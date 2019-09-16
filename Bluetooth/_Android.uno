using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
	[ForeignInclude(Language.Java, "com.foreign.Uno.*")]

	extern(Android)
	internal class Bluetooth_Android: IBluetooth, IDisposable	
	{
		extern(Android) Java.Object _impl;

		[Foreign(Language.Java)]
		public void Create(Action open, Action close, Action<string> error, Action<byte[]> receive)
		@{

		@}

		[Foreign(Language.Java)]
		public void Connect()
		@{

		@}

		[Foreign(Language.Java)]
		public void Disconnect()
		@{

		@}

		[Foreign(Language.Java)]
		public void Send(byte[] data)
		@{

		@}

		public void Dispose()
		{

		}
	}
}

