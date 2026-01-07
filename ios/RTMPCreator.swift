//
//  RTMPCreator.swift
//  rtmpPackageExample
//
//  Created by Ezran Bayantemur on 15.01.2022.
//
import HaishinKit
import Foundation
import AVFoundation
import VideoToolbox

struct VideoSettingsType {
    var width: Int
    var height: Int
    var bitrate: Int
    var audioBitrate: Int
}

class RTMPCreator {
    public static let connection: RTMPConnection = RTMPConnection()
    public static let stream: RTMPStream = RTMPStream(connection: connection)
    private static let captureQueue = DispatchQueue(label: "com.sportninja.rtmp.capture")
    private static let session = AVAudioSession.sharedInstance()
    private static var _streamUrl: String = ""
    private static var _streamName: String = ""
    public static var isStreaming: Bool = false
    public static var videoSettings: VideoSettingsType = VideoSettingsType(
        width: 720,
        height: 1280,
        bitrate: 3000 * 1024,
        audioBitrate: 128 * 1000
    )

    public static func setStreamUrl(url: String){
        _streamUrl = url
    }

    public static func setStreamName(name: String){
        _streamName = name
    }

  
    public static func getPublishURL() -> String {
    // TODO: Object formatına dönüştürülebilir
    /**
      {
        streamName: _streamName
        streamUrl: _streamUrl
      }
     */
    return "\(_streamUrl)/\(_streamName)"
    }
  
    public static func startPublish(){
        performCaptureConfiguration {
            connection.requireNetworkFramework = true
            connection.connect(_streamUrl)
            stream.publish(_streamName)
            isStreaming = true
        }
    }

    public static func performCaptureConfiguration(_ block: @escaping () -> Void) {
        captureQueue.async {
            block()
        }
    }

    public static func setVideoSettings(_ newVideoSettings: VideoSettingsType) {
        videoSettings = newVideoSettings
        performCaptureConfiguration {
            stream.videoSettings = [
                .width: videoSettings.width,
                .height: videoSettings.height,
                .bitrate: videoSettings.bitrate,
                .scalingMode: ScalingMode.cropSourceToCleanAperture,
                .profileLevel: kVTProfileLevel_H264_High_AutoLevel
            ]

            stream.audioSettings = [
                .bitrate: videoSettings.audioBitrate
            ]
        }
    }

    public static func stopPublish(){
        performCaptureConfiguration {
            stream.close()
            connection.close()
            isStreaming = false
        }
    }
    
    public static func setAudioInput(audioInput: Int){
        performCaptureConfiguration {
            switch audioInput {
            case 0:
                switchToBluetooth()
                break;

            case 1:
                switchToSpeaker()
                break;

            case 2:
                switchToHeadset()
                break;

            default:
                return
            }
        }
    }
    
    private static func switchToSpeaker(){
        guard let inputs = session.availableInputs, !inputs.isEmpty else {
            NSLog("RTMPCreator: No available audio inputs for speaker switch.")
            return
        }
        
        if let selectedDesc = inputs.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSession.Port.builtInMic
        }){
            do{
                
                let selectedDataSource = selectedDesc.dataSources?.first(where: { (source) -> Bool in
                    return source.orientation == AVAudioSession.Orientation.front
                })
                
                try session.setPreferredInput(selectedDesc)
                try session.setInputDataSource(selectedDataSource)
            } catch let error{
                print(error)
            }
        }
    }
      
    private static func switchToHeadset(){
        guard let inputs = session.availableInputs, !inputs.isEmpty else {
            NSLog("RTMPCreator: No available audio inputs for headset switch.")
            return
        }

        if let selectedDesc = inputs.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSession.Port.headsetMic
        }){
            do{
                try session.setPreferredInput(selectedDesc)
            } catch let error{
                print(error)
            }
        }
    }
    
    private static func switchToBluetooth(){
        guard let inputs = session.availableInputs, !inputs.isEmpty else {
            NSLog("RTMPCreator: No available audio inputs for bluetooth switch.")
            return
        }
        
        if let selectedDesc = inputs.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSession.Port.bluetoothHFP
        }){
            do{
                try session.setPreferredInput(selectedDesc)
            } catch let error{
                print(error)
            }
        }
    }
      

}
