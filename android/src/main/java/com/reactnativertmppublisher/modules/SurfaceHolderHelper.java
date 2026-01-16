package com.reactnativertmppublisher.modules;


import android.util.Log;
import android.view.SurfaceHolder;

import androidx.annotation.NonNull;

import com.facebook.react.uimanager.ThemedReactContext;
import com.pedro.rtplibrary.rtmp.RtmpCamera1;

public class SurfaceHolderHelper implements SurfaceHolder.Callback {
  private static final String TAG = "SurfaceHolderHelper";
  private final RtmpCamera1 _rtmpCamera1;

  public SurfaceHolderHelper(ThemedReactContext reactContext, RtmpCamera1 rtmpCamera1, int surfaceId) {
    _rtmpCamera1 = rtmpCamera1;
  }

  @Override
  public void surfaceCreated(@NonNull SurfaceHolder surfaceHolder) {

  }

  @Override
  public void surfaceChanged(@NonNull SurfaceHolder surfaceHolder, int i, int i1, int i2) {
    try {
      if (_rtmpCamera1 != null && !_rtmpCamera1.isOnPreview()) {
        _rtmpCamera1.startPreview(1280, 720);
      }
    } catch (Exception e) {
      Log.e(TAG, "Failed to start preview", e);
    }
  }

  @Override
  public void surfaceDestroyed(@NonNull SurfaceHolder surfaceHolder) {
    try {
      if (_rtmpCamera1 != null && _rtmpCamera1.isOnPreview()) {
        _rtmpCamera1.stopPreview();
      }
    } catch (Exception e) {
      Log.e(TAG, "Failed to stop preview", e);
    }
  }

}
