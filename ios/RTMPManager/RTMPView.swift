//
//  RTMPView.swift
//  rtmpPackageExample
//
//  Created by Ezran Bayantemur on 15.01.2022.
//

import UIKit
import HaishinKit
import AVFoundation

class RTMPView: UIView {
  private var hkView: MTHKView!
  private var pendingAudioUpdateAttempts = 0
  private let maxAudioUpdateAttempts = 10
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
      updateAudioAttachment()
    }
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
      RTMPCreator.stream.attachAudio(AVCaptureDevice.default(for: .audio))
    } else {
      RTMPCreator.stream.attachAudio(nil)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    UIApplication.shared.isIdleTimerDisabled = true
    
    hkView = MTHKView(frame: UIScreen.main.bounds)
    hkView.videoGravity = .resizeAspectFill
    
    RTMPCreator.stream.captureSettings = [
        .fps: 30,
        .sessionPreset: AVCaptureSession.Preset.hd1920x1080,
        .continuousAutofocus: true,
        .continuousExposure: true
    ]

    RTMPCreator.stream.videoSettings = [
        .width: 720,
        .height: 1280,
        .bitrate: 3000 * 1024,
        .scalingMode: ScalingMode.cropSourceToCleanAperture
        
    ]

    updateAudioAttachment()
    RTMPCreator.stream.attachCamera(DeviceUtil.device(withPosition: AVCaptureDevice.Position.back))

    RTMPCreator.connection.addEventListener(.rtmpStatus, selector: #selector(statusHandler), observer: self)

    hkView.attachStream(RTMPCreator.stream)

    self.addSubview(hkView)
      
}
    
    required init?(coder aDecoder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
     }
    
    override func removeFromSuperview() {
        print("ON REMOVE")
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
