//
//  RTMPView.swift
//  rtmpPackageExample
//
//  Created by Ezran Bayantemur on 15.01.2022.
//

import UIKit
import HaishinKit
import AVFoundation
import VideoToolbox

class RTMPView: UIView {
  private var hkView: MTHKView!
  private var pendingAudioUpdateAttempts = 0
  private let maxAudioUpdateAttempts = 10
  private var hasAppliedInitialSettings = false
  private var hasAttachedStream = false
  @objc var onDisconnect: RCTDirectEventBlock?
  @objc var onConnectionFailed: RCTDirectEventBlock?
  @objc var onConnectionStarted: RCTDirectEventBlock?
  @objc var onConnectionSuccess: RCTDirectEventBlock?
  @objc var onNewBitrateReceived: RCTDirectEventBlock?
  @objc var onStreamStateChanged: RCTDirectEventBlock?
  
  @objc var streamURL: NSString = "" {
    didSet {
      RTMPCreator.setStreamUrl(url: streamURL as String)
    }
  }
  
  @objc var streamName: NSString = "" {
    didSet {
      RTMPCreator.setStreamName(name: streamName as String)
    }
  }
  @objc var enableAudio: Bool = true {
    didSet {
      guard hasAttachedStream else { return }
      updateAudioAttachment()
    }
  }

  @objc var videoSettings: NSDictionary = NSDictionary(
      dictionary: [
        "width": 720,
        "height": 1280,
        "bitrate": 3000 * 1000,
        "audioBitrate": 128 * 1000,
        "fps": 30
      ]
  ){
    didSet {
        guard hasAttachedStream else { return }
        applyVideoSettings()
    }
  }

  private func applyVideoSettings() {
      let width = videoSettings["width"] as? Int ?? 720
      let height = videoSettings["height"] as? Int ?? 1280
      let bitrate = videoSettings["bitrate"] as? Int ?? (3000 * 1000)
      let audioBitrate = videoSettings["audioBitrate"] as? Int ?? (128 * 1000)
      let fps = videoSettings["fps"] as? Int ?? 30

      // Update capture preset to match output resolution
      let preset = selectCapturePreset(for: width, height: height)
      RTMPCreator.performCaptureConfiguration {
        RTMPCreator.stream.captureSettings[.sessionPreset] = preset
      }

      RTMPCreator.setVideoSettings(VideoSettingsType(width: width, height: height, bitrate: bitrate, audioBitrate: audioBitrate, fps: fps))
  }

  @objc var videoOrientation: NSString = "portrait" {
    didSet {
      guard hasAttachedStream else { return }
      applyVideoOrientation()
    }
  }

  private func applyVideoOrientation() {
    RTMPCreator.performCaptureConfiguration {
      switch self.videoOrientation {
      case "landscape":
        RTMPCreator.stream.videoOrientation = AVCaptureVideoOrientation.landscapeRight
      default:
        RTMPCreator.stream.videoOrientation = AVCaptureVideoOrientation.portrait
      }
    }
  }

  private func cleanup() {
    // Stop streaming if active
    if RTMPCreator.isStreaming {
      RTMPCreator.stopPublish()
    }

    // Detach view from stream (critical - prevents crash)
    if hasAttachedStream {
      hkView.attachStream(nil)
      hasAttachedStream = false
    }

    // Remove event listener
    RTMPCreator.connection.removeEventListener(.rtmpStatus, selector: #selector(statusHandler), observer: self)

    // Detach camera and audio
    RTMPCreator.performCaptureConfiguration {
      RTMPCreator.stream.attachCamera(nil)
      RTMPCreator.stream.attachAudio(nil)
    }

    // Re-enable idle timer
    UIApplication.shared.isIdleTimerDisabled = false
  }

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()

    do {
      try session.setCategory(
        .playAndRecord,
        mode: .videoChat,
        options: [.defaultToSpeaker, .allowBluetooth]
      )
      try session.setPreferredSampleRate(44100)
      try session.setPreferredIOBufferDuration(0.005)

      if let input = session.availableInputs?.first(where: { input in
        return input.portType == .builtInMic
      }) {
        try session.setPreferredInput(input)
      }

      try session.setActive(true)
    } catch {
      NSLog("RTMPView: Failed to configure AVAudioSession: %@", error.localizedDescription)
    }
  }

  private func updateAudioAttachment() {
    if RTMPCreator.isStreaming {
      if pendingAudioUpdateAttempts >= maxAudioUpdateAttempts {
        NSLog("RTMPView: Skipping audio update; stream still active.")
        return
      }

      pendingAudioUpdateAttempts += 1
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        self?.updateAudioAttachment()
      }
      return
    }

    pendingAudioUpdateAttempts = 0
    if enableAudio {
      configureAudioSession()
      RTMPCreator.performCaptureConfiguration {
        RTMPCreator.stream.attachAudio(AVCaptureDevice.default(for: .audio))
      }
    } else {
      RTMPCreator.performCaptureConfiguration {
        RTMPCreator.stream.attachAudio(nil)
      }
    }
  }

  private func selectCapturePreset(for width: Int, height: Int) -> AVCaptureSession.Preset {
      let maxDimension = max(width, height)
      if maxDimension <= 640 {
          return .vga640x480
      } else if maxDimension <= 1280 {
          return .hd1280x720
      } else {
          return .hd1920x1080
      }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    UIApplication.shared.isIdleTimerDisabled = true

    hkView = MTHKView(frame: UIScreen.main.bounds)
    hkView.videoGravity = .resizeAspectFill

    RTMPCreator.connection.addEventListener(.rtmpStatus, selector: #selector(statusHandler), observer: self)

    self.addSubview(hkView)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    hkView.frame = self.bounds

    if !hasAppliedInitialSettings {
      hasAppliedInitialSettings = true
      performInitialSetup()
    }
  }

  private func performInitialSetup() {
    let configGroup = DispatchGroup()

    // Configure basic capture settings (NOT encoding settings)
    RTMPCreator.performCaptureConfiguration(group: configGroup) {
      RTMPCreator.stream.captureSettings = [
        .continuousAutofocus: true,
        .continuousExposure: true
      ]
    }

    // Configure audio session and attach audio
    configureAudioSession()
    if enableAudio {
      RTMPCreator.performCaptureConfiguration(group: configGroup) {
        RTMPCreator.stream.attachAudio(AVCaptureDevice.default(for: .audio))
      }
    }

    // Attach camera
    RTMPCreator.performCaptureConfiguration(group: configGroup) {
      RTMPCreator.stream.attachCamera(DeviceUtil.device(withPosition: AVCaptureDevice.Position.back))
    }

    // CRITICAL: Attach stream AFTER camera/audio attached, but BEFORE encoding settings
    configGroup.notify(queue: .main) { [weak self] in
      guard let self = self else { return }
      self.hkView.attachStream(RTMPCreator.stream)
      self.hasAttachedStream = true

      // Apply encoding settings AFTER stream is attached (like old code)
      self.applyVideoSettings()
      self.applyVideoOrientation()
    }
  }
    
    required init?(coder aDecoder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
     }
    
    override func removeFromSuperview() {
        cleanup()
        super.removeFromSuperview()
    }

    deinit {
        cleanup()
    }
  
    @objc
    private func statusHandler(_ notification: Notification){
      let e = Event.from(notification)
       guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
           return
       }
    
       switch code {
       case RTMPConnection.Code.connectSuccess.rawValue:
         if onConnectionSuccess != nil {
              onConnectionSuccess!(nil)
            }
           changeStreamState(status: "CONNECTING")
           RTMPCreator.stream.publish(streamName as String)
           break
       
       case RTMPConnection.Code.connectFailed.rawValue:
         if onConnectionFailed != nil {
              onConnectionFailed!(nil)
            }
           changeStreamState(status: "FAILED")
           break
         
       case RTMPConnection.Code.connectClosed.rawValue:
         if onDisconnect != nil {
              onDisconnect!(nil)
            }
           changeStreamState(status: "CLOSED")
           break
         
       case RTMPStream.Code.publishStart.rawValue:
         if onConnectionStarted != nil {
              onConnectionStarted!(nil)
            }
           changeStreamState(status: "CONNECTED")
           break
         
       default:
           break
       }
    }

    public func changeStreamState(status: String){
      if onStreamStateChanged != nil {
        onStreamStateChanged!(["data": status])
       }
    }
}
