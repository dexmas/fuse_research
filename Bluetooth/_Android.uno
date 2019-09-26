using Uno;
using Uno.Collections;
using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
	[ForeignInclude(Language.Java, "com.foreign.Uno.*")]

	extern(Android)
	internal class Bluetooth_Android: IBluetooth, IDisposable	
	{
		extern(Android) Java.Object _impl;

		public Bluetooth_Android() {
			RequestPermissions();
		}

		[Foreign(Language.Java)]
		public void Create(Action open, Action close, Action<string> error, Action<string> dfound, Action<byte[]> receive)
		@{
			com.blackcat.BluetoothImpl impl = new com.blackcat.BluetoothImpl(dfound);
            @{Bluetooth_Android:Of(_this)._impl:Set(impl)};
		@}

		[Foreign(Language.Java)]
		public void List() 
		@{
			com.blackcat.BluetoothImpl impl = (com.blackcat.BluetoothImpl)@{Bluetooth_Android:Of(_this)._impl:Get()};
            impl.List();
		@}

		[Foreign(Language.Java)]
		public void Connect(string _name)
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

		void RequestPermissions()
		{
			var permissions = new PlatformPermission[] 
			{
				Permissions.Android.BLUETOOTH,
				Permissions.Android.BLUETOOTH_ADMIN,
				Permissions.Android.BLUETOOTH_PRIVILEGED
			};
			
			Permissions.Request(permissions).Then(OnPermissionsResult, OnPermissionsError);
		}
		
		void OnPermissionsResult(PlatformPermission[] grantedPermissions)
		{

		}
		
		void OnPermissionsError(Exception e)
		{

		}

		public void Dispose()
		{

		}
	}
}

