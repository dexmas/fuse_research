using Uno;
using Uno.UX;
using Fuse.Scripting;

namespace BlackCat
{
	[UXGlobalModule]
	public class DiscoveryModule : NativeEventEmitterModule
	{
        static readonly DiscoveryModule _instance;
        readonly Discovery _discovery;

        public DiscoveryModule() : base(true, "list")
		{
            if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "BlackCat/Discovery");

            _discovery = new Discovery();
            _discovery.Callback = _Callback;

            AddMember(new NativeFunction("Search", (NativeCallback)_Search));
        }

        void _Callback(string list)
        {
            Emit("list", list);
        }

        object _Search(Context c, object[] args)
		{
            _discovery.Search();
			return null;
		}
    }
}