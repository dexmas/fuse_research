package com.blackcat;

import android.hardware.*;
import android.content.Context;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;

import android.os.Handler;
import android.os.Message;

import com.fuse.Activity;

public class BluetoothImpl
{
	private BluetoothAdapter bluetoothAdapter;
	private BluetoothService bluetoothSerialService;

	// Message types sent from the BluetoothService Handler
	public static final int MESSAGE_STATE_CHANGE = 1;
	public static final int MESSAGE_READ = 2;
	public static final int MESSAGE_WRITE = 3;
	public static final int MESSAGE_DEVICE_NAME = 4;
	public static final int MESSAGE_TOAST = 5;
	public static final int MESSAGE_READ_RAW = 6;

	StringBuffer buffer = new StringBuffer();
	private String delimiter;

	public BluetoothImpl()
	{
		Context context = (Context)Activity.getRootActivity();

		if (bluetoothAdapter == null) {
			bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
		}

		if (bluetoothSerialService == null) {
			bluetoothSerialService = new BluetoothService(mHandler);
		}
	}

    public void Destroy() {
        if (bluetoothSerialService != null) {
            bluetoothSerialService.stop();
        }
    }

	// The Handler that gets information back from the BluetoothService
	// Original code used handler for the because it was talking to the UI.
	// Consider replacing with normal callbacks
	private final Handler mHandler = new Handler() 
	{
		public void handleMessage(Message msg) {
			switch (msg.what) {
				case MESSAGE_READ:
					buffer.append((String)msg.obj);

					//if (dataAvailableCallback != null) {
					//	sendDataToSubscriber();
					//}

					break;
				case MESSAGE_READ_RAW:
					//if (rawDataAvailableCallback != null) {
					//	byte[] bytes = (byte[]) msg.obj;
					//	sendRawDataToSubscriber(bytes);
					//}
					break;
				case MESSAGE_STATE_CHANGE:

					/*if(D) Log.i(TAG, "MESSAGE_STATE_CHANGE: " + msg.arg1);
					switch (msg.arg1) {
						case BluetoothService.STATE_CONNECTED:
							Log.i(TAG, "BluetoothService.STATE_CONNECTED");
							notifyConnectionSuccess();
							break;
						case BluetoothService.STATE_CONNECTING:
							Log.i(TAG, "BluetoothService.STATE_CONNECTING");
							break;
						case BluetoothService.STATE_LISTEN:
							Log.i(TAG, "BluetoothService.STATE_LISTEN");
							break;
						case BluetoothService.STATE_NONE:
							Log.i(TAG, "BluetoothService.STATE_NONE");
							break;
					}*/
					break;
				case MESSAGE_WRITE:
					//  byte[] writeBuf = (byte[]) msg.obj;
					//  String writeMessage = new String(writeBuf);
					//  Log.i(TAG, "Wrote: " + writeMessage);
					break;
				case MESSAGE_DEVICE_NAME:
					//Log.i(TAG, msg.getData().getString(DEVICE_NAME));
					break;
				case MESSAGE_TOAST:
					//String message = msg.getData().getString(TOAST);
					//notifyConnectionLost(message);
					break;
			}
		}
	};
}