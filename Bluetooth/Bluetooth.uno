using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
	internal interface IBluetooth
	{
		void Create(Action open, Action close, Action<string> error, Action<string> dfound, Action<byte[]> receive);
		void List();
		void Send(byte[] data);
		void Connect(string _name);
		void Disconnect();
	}

	public class Bluetooth_Stub: IBluetooth
	{
		public void Create(Action open, Action close, Action<string> error, Action<string> dfound, Action<byte[]> receive) {}
		public void List() {}
		public void Send(byte[] _data) {}
		public void Connect(string _name) {}
		public void Disconnect() {}
	}

	public class Bluetooth
	{
		readonly IBluetooth _impl;

		public Action OnOpen;
		public Action<string> OnError;
		public Action OnClosed;
		public Action<string> OnDeviceFound;
		public Action<byte[]> OnRecieve;

		public Bluetooth()
		{
			if defined(Android)
			{
				_impl = new Bluetooth_Android();
			}
			else if defined(iOS)
			{
				_impl = new Bluetooth_iOS();
			} 
			else 
			{
				_impl = new Bluetooth_Stub();
			}

			_impl.Create(_OnOpen, _OnClose, _OnError, _OnDeviceFound, _OnReceive);
		}

		void _OnOpen()
		{
			if (OnOpen != null)
				OnOpen();
		}

		void _OnClose()
		{
			if (OnClosed != null)
				OnClosed();
		}

		void _OnDeviceFound(string device)
		{
			if (OnDeviceFound != null)
				OnDeviceFound(device);
		}

		void _OnReceive(byte[] data)
		{
			if (OnRecieve != null)
				OnRecieve(data);
		}

		void _OnError(string error)
		{
			if (OnError != null)
				OnError(error);
		}

		public void List()
		{
			_impl.List();
		}

		public void Send(byte[] _data)
		{
			_impl.Send(_data);
		}

		public void Connect(string _name)
		{
			_impl.Connect(_name);
		}

		public void Disconnect()
		{
			_impl.Disconnect();
		}
	}
}
