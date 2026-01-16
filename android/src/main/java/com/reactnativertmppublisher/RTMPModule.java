package com.reactnativertmppublisher;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.reactnativertmppublisher.enums.AudioInputType;

public class RTMPModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
  private static final String TAG = "RTMPModule";
  private final String REACT_MODULE_NAME = "RTMPPublisher";
  private final ReactApplicationContext _reactContext;
  private boolean _wasStreaming = false;

  public RTMPModule(@Nullable ReactApplicationContext reactContext) {
    super(reactContext);
    _reactContext = reactContext;
    if (reactContext != null) {
      reactContext.addLifecycleEventListener(this);
    }
  }

  @Override
  public void onHostResume() {
    Log.d(TAG, "onHostResume");
    if (RTMPManager.publisher != null) {
      RTMPManager.publisher.handleResume();

      // Emit event to JS with wasStreaming info
      WritableMap params = Arguments.createMap();
      params.putBoolean("wasStreaming", _wasStreaming);
      sendEvent("onAppForegrounded", params);
    }
  }

  @Override
  public void onHostPause() {
    Log.d(TAG, "onHostPause");
    if (RTMPManager.publisher != null) {
      _wasStreaming = RTMPManager.publisher.handlePause();

      // Emit event to JS
      WritableMap params = Arguments.createMap();
      params.putBoolean("wasStreaming", _wasStreaming);
      sendEvent("onAppBackgrounded", params);
    }
  }

  @Override
  public void onHostDestroy() {
    Log.d(TAG, "onHostDestroy");
    if (RTMPManager.publisher != null) {
      RTMPManager.publisher.handleDestroy();
    }
    if (_reactContext != null) {
      _reactContext.removeLifecycleEventListener(this);
    }
  }

  private void sendEvent(String eventName, @Nullable WritableMap params) {
    if (_reactContext != null && _reactContext.hasActiveReactInstance()) {
      _reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
    }
  }

  @NonNull
  @Override
  public String getName() {
    return REACT_MODULE_NAME;
  }

  @ReactMethod
  public void isStreaming(Promise promise) {
    try {
      boolean streamStatus = RTMPManager.publisher.isStreaming();
      promise.resolve(streamStatus);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isCameraOnPreview(Promise promise) {
    try {
      boolean streamStatus = RTMPManager.publisher.isOnPreview();
      promise.resolve(streamStatus);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void getPublishURL(Promise promise) {
    try {
      String url = RTMPManager.publisher.getPublishURL();
      promise.resolve(url);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void hasCongestion(Promise promise) {
    try {
      boolean congestionStatus = RTMPManager.publisher.hasCongestion();
      promise.resolve(congestionStatus);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isAudioPrepared(Promise promise) {
    try {
      boolean status = RTMPManager.publisher.isAudioPrepared();
      promise.resolve(status);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isVideoPrepared(Promise promise) {
    try {
      boolean status = RTMPManager.publisher.isVideoPrepared();
      promise.resolve(status);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isMuted(Promise promise) {
    try {
      boolean status = RTMPManager.publisher.isAudioMuted();
      promise.resolve(status);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void mute(Promise promise) {
    try {
      if (RTMPManager.publisher.isAudioMuted()) {
        return;
      }

      RTMPManager.publisher.disableAudio();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void unmute(Promise promise) {
    try {
      if (!RTMPManager.publisher.isAudioMuted()) {
        return;
      }

      RTMPManager.publisher.enableAudio();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void switchCamera(Promise promise) {
    try {
      RTMPManager.publisher.switchCamera();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void startStream(Promise promise) {
    try {
      RTMPManager.publisher.startStream();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void stopStream(Promise promise) {
    try {
      RTMPManager.publisher.stopStream();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void toggleFlash(Promise promise) {
    try {
      RTMPManager.publisher.toggleFlash();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void setAudioInput(int audioInputType, Promise promise) {
    try {
      AudioInputType selectedType = AudioInputType.values()[audioInputType];
      RTMPManager.publisher.setAudioInput(selectedType);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void setVideoSettings(ReadableMap videoSettings, Promise promise) {
    try {
      int width = videoSettings.hasKey("width") ? videoSettings.getInt("width") : 1280;
      int height = videoSettings.hasKey("height") ? videoSettings.getInt("height") : 720;
      int bitrate = videoSettings.hasKey("bitrate") ? videoSettings.getInt("bitrate") : 3000 * 1024;
      int audioBitrate = videoSettings.hasKey("audioBitrate") ? videoSettings.getInt("audioBitrate") : 128 * 1024;
      int fps = videoSettings.hasKey("fps") ? videoSettings.getInt("fps") : 30;

      RTMPManager.publisher.setVideoSettings(width, height, bitrate, audioBitrate, fps);
      promise.resolve(null);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void setZoom(int zoomLevel, Promise promise) {
    try {
      RTMPManager.publisher.setZoom(zoomLevel);
      promise.resolve(zoomLevel);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void getMaxZoom(Promise promise) {
    try {
      int maxZoom = RTMPManager.publisher.getMaxZoom();
      promise.resolve(maxZoom);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void getMinZoom(Promise promise) {
    try {
      int minZoom = RTMPManager.publisher.getMinZoom();
      promise.resolve(minZoom);
    } catch (Exception e) {
      promise.reject(e);
    }
  }
}
