using Uno;
using Uno.UX;
using Fuse.Scripting;

namespace BlackCat
{
	[UXGlobalModule]
	public class BluetoothModule : NativeEventEmitterModule
	{
		static readonly BluetoothModule _instance;
		readonly Bluetooth _bluetooth;

		public BluetoothModule() : base(true, "open", "error", "close", "receive")
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "BlackCat/Bluetooth");

			_bluetooth = new Bluetooth();
			_bluetooth.OnOpen = _OnOpen;
			_bluetooth.OnError = _OnError;
			_bluetooth.OnClosed = _OnClosed;
			_bluetooth.OnRecieve = _OnRecieve;

			AddMember(new NativeFunction("list", (NativeCallback)_List));
			AddMember(new NativeFunction("connect", (NativeCallback)_Connect));
			AddMember(new NativeFunction("disconnect", (NativeCallback)_Disconnect));
			AddMember(new NativeFunction("send", (NativeCallback)_Send));
		}

		void _OnOpen()
		{
			Emit("open", "");
		}

		void _OnError(string message)
		{
			Emit("error", message);
		}

		void _OnClosed()
		{
			Emit("close", "");
		}

		void _OnRecieve(byte[] data)
		{
			Emit("receive", data);
		}

		object _List(Context c, object[] args)
		{
			_bluetooth.List();
			return null;
		}

		object _Connect(Context c, object[] args)
		{
			_bluetooth.Connect(args[0] as string);
			
			return null;
		}

		object _Disconnect(Context c, object[] args)
		{
			_bluetooth.Disconnect();
			return null;
		}

		object _Send(Context c, object[] args)
		{
			if (args != null && args.Length > 0)
			{
				var a = args[0];

				if (a is byte[])
				{
					var b = a as byte[];
					_bluetooth.Send(b);
				}
			}
			return null;
		}
	}
}

