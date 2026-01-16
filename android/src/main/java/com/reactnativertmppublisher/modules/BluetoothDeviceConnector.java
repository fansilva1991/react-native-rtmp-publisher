package com.reactnativertmppublisher.modules;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import com.reactnativertmppublisher.enums.BluetoothDeviceStatuses;
import com.reactnativertmppublisher.interfaces.ConnectionListener;

import java.util.ArrayList;
import java.util.List;

public class BluetoothDeviceConnector extends BroadcastReceiver implements BluetoothProfile.ServiceListener{
  private final List<ConnectionListener> listeners = new ArrayList<>();
  private Context _context;
  private boolean _isRegistered = false;

  public void addListener(ConnectionListener listener) {
    listeners.add(listener);
  }

  public BluetoothDeviceConnector(Context context) {
    _context = context;
    BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    if (mBluetoothAdapter != null) {
      mBluetoothAdapter.getProfileProxy(context, this, BluetoothProfile.HEADSET);
    }
    try {
      context.registerReceiver(this, new IntentFilter(BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED));
      _isRegistered = true;
    } catch (Exception e) {
      Log.e("BluetoothConnector", "Failed to register receiver", e);
    }
  }

  public void unregister() {
    if (_context != null && _isRegistered) {
      try {
        _context.unregisterReceiver(this);
        _isRegistered = false;
      } catch (Exception e) {
        Log.e("BluetoothConnector", "Failed to unregister receiver", e);
      }
    }
  }

  public void clearListeners() {
    listeners.clear();
  }

  @Override
  public void onServiceConnected(int i, BluetoothProfile bluetoothProfile) {
    if(bluetoothProfile.getConnectedDevices().size() > 0) {
        for (ConnectionListener l : listeners) {
        l.onChange("onBluetoothDeviceStatusChanged", BluetoothDeviceStatuses.CONNECTED.toString());
      }
    }
  }

  @Override
  public void onServiceDisconnected(int i) {
    for (ConnectionListener l : listeners) {
      l.onChange("onBluetoothDeviceStatusChanged", BluetoothDeviceStatuses.DISCONNECTED.toString());
    }
  }

  @Override
  public void onReceive(Context context, Intent intent) {
    int status = intent.getIntExtra(BluetoothAdapter.EXTRA_CONNECTION_STATE, -1);

    switch (status){
      case BluetoothAdapter.STATE_CONNECTING: {
        for (ConnectionListener l : listeners) {
          l.onChange("onBluetoothDeviceStatusChanged", BluetoothDeviceStatuses.CONNECTING.toString());
        };
        break;
      }

      case BluetoothAdapter.STATE_CONNECTED: {
        for (ConnectionListener l : listeners) {
          l.onChange("onBluetoothDeviceStatusChanged", BluetoothDeviceStatuses.CONNECTED.toString());
        };
        break;
      }

      case BluetoothAdapter.STATE_DISCONNECTED: {
        for (ConnectionListener l : listeners) {
          l.onChange("onBluetoothDeviceStatusChanged", BluetoothDeviceStatuses.DISCONNECTED.toString());
        };
        break;
      }
    };

  }
}
