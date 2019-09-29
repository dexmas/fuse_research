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

		[Foreign(Language.ObjC)]
		public void Create(Action open, Action close, Action<string> error, Action<string> dfound, Action<byte[]> receive)
		@{
			BluetoothImpl* impl = [[BluetoothImpl alloc] Init: dfound];
			@{Bluetooth_iOS:Of(_this)._impl:Set(impl)};
		@}

		[Foreign(Language.ObjC)]
		public void List() 
		@{
			BluetoothImpl* impl = @{Bluetooth_iOS:Of(_this)._impl:Get()};
			[impl scan: 10];
		@}

		[Foreign(Language.ObjC)]
		public void Connect(string _name)
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
