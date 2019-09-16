using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
	[Require("Xcode.Framework", "CoreBluetooth.framework")]
	[Require("Source.Include", "BluetoothImpl.hh")]
	extern(iOS)
	internal class Bluetooth_iOS: IBluetooth, IDisposable
	{
		extern(iOS) ObjC.Object _impl;

		public void Create(Action open, Action close, Action<string> error, Action<byte[]> receive)
		{

		}

		[Foreign(Language.ObjC)]
		public void Connect()
		@{

		@}

		[Foreign(Language.ObjC)]
		public void Disconnect()
		@{

		@}

		[Foreign(Language.ObjC)]
		public void Send(byte[] data)
		@{
			const uint8_t *arrPtr = (const uint8_t *)[data unoArray]->Ptr();
		@}

		public void Dispose()
		{
			
		}
	}
}
