using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
	internal interface IBluetooth
	{
		void Create(Action open, Action close, Action<string> error, Action<byte[]> receive);
		void Send(byte[] data);
		void Connect();
		void Disconnect();
	}

	public class Bluetooth_Stub: IBluetooth, IDisposable
	{
		public void Create(Action open, Action close, Action<string> error, Action<byte[]> receive) {}
		public void Send(byte[] data) {}
		public void Connect() {}
		public void Disconnect() {}
		public void Dispose() {}
	}

	public class Bluetooth
	{
		readonly IBluetooth _impl;

		public Action OnOpen;
		public Action<string> OnError;
		public Action OnClosed;
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

			_impl.Create(_OnOpen, _OnClose, _OnError, _OnReceive);
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

		public void Send(byte[] data)
		{
			_impl.Send(data);
		}

		public void Connect()
		{
			_impl.Connect();
		}

		public void Disconnect()
		{
			_impl.Disconnect();
		}
	}
}