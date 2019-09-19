using Uno;
using Uno.UX;
using Fuse;
using Fuse.Scripting;
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
    
	[UXGlobalModule]
	public class DiscoveryModule : NativeEventEmitterModule
	{
        static readonly DiscoveryModule _instance;

        extern(Android) com.blackcat.serviceDiscovery _impl;
		//extern(iOS) serviceDiscovery* _impl;

        [Foreign(Language.Java)]
        public extern(Android) DiscoveryModule() : base(true, "list")
		@{
            if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "BlackCat/Discovery");

            _impl = new com.blackcat.serviceDiscovery();

            AddMember(new NativeFunction("discover", (NativeCallback)_Discover));
        @}

        [Foreign(Language.ObjC)]
        public extern(iOS) DiscoveryModule() : base(true, "list")
		@{
            if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "BlackCat/Discovery");

            _impl = [serviceDiscovery alloc];

            AddMember(new NativeFunction("discover", (NativeCallback)_Discover));
        @}

        static object[] _ListFactory(Context context, object[] list)
		{
			return list;
		}

        [Foreign(Language.Java)]
        extern(Android) void _Callback()
        @{
            EmitFactory(_ListFactory, list);
        @}

        [Foreign(Language.Java)]
        extern(Android) object _Discover(Context c, object[] args)
		@{
            _impl.search("", _Callback);
			return null;
		@}

        [Foreign(Language.ObjC)]
        extern(iOS) object _Discover(Context c, object[] args)
		@{
            [_impl getNetworkServices: ^(NSString* result, NSMutableArray* array) {
                object[] list = new object[] { "1", "one" };
                EmitFactory(_ListFactory, list);
            }];
			return null;
		@}

        public extern(!MOBILE) DiscoveryModule() : base(true, "list") 
        {
            if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "BlackCat/Discovery");

            AddMember(new NativeFunction("discover", (NativeCallback)_Discover));
        }

		public extern(!MOBILE) object _Discover(Context c, object[] args) {return null;}
    }
}