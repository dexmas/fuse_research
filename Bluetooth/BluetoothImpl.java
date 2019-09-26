package com.blackcat;

import android.hardware.*;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.os.Handler;
import android.os.Message;

import android.app.Activity;
import android.util.Log;

import com.foreign.Uno.*;

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

	private static final String TAG = "BluetoothSerial";

	StringBuffer buffer = new StringBuffer();
	private String delimiter;

	Action_String Callback;

	private JSONObject deviceToJSON(BluetoothDevice device) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("name", device.getName());
        json.put("address", device.getAddress());
        json.put("id", device.getAddress());
        if (device.getBluetoothClass() != null) {
            json.put("class", device.getBluetoothClass().getDeviceClass());
        }
        return json;
    }

	public BluetoothImpl(Action_String _callback)
	{
		Callback = _callback;

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

	public void List() {
        final BroadcastReceiver discoverReceiver = new BroadcastReceiver() {

            private JSONArray unpairedDevices = new JSONArray();

            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    try {
                    	JSONObject o = deviceToJSON(device);
                        unpairedDevices.put(o);
						Callback.run(o.toString());
                    } catch (JSONException e) {
                        // This shouldn't happen, log and ignore
                        Log.e(TAG, "Problem converting device to JSON", e);
                    }
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                    //Callback.run(unpairedDevices.toString());
                }
            }
        };

        Activity activity = com.fuse.Activity.getRootActivity();
        activity.registerReceiver(discoverReceiver, new IntentFilter(BluetoothDevice.ACTION_FOUND));
        activity.registerReceiver(discoverReceiver, new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED));

        bluetoothAdapter.startDiscovery();
	}

	public void Connect(String _name) {
		boolean secure = false;
		String macAddress = _name;
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);

        if (device != null) {
            bluetoothSerialService.connect(device, secure);
            buffer.setLength(0);
            //TODO: Return result (connected)

        } else {
            Log.e(TAG, "Could not connect to " + macAddress);
        }
	}

	public void Disconnect() {
		bluetoothSerialService.stop();
	}

	public void Send(byte[] _data) {
        bluetoothSerialService.write(_data);
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