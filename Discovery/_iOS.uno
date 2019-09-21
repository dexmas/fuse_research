using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
    [Require("Xcode.Framework", "Foundation.framework")]
	[ForeignInclude(Language.ObjC, "serviceDiscovery.h")]

	extern(iOS)
	internal class Discovery_iOS: IDiscovery, IDisposable	
	{
		ObjC.Object _impl;

		[Foreign(Language.ObjC)]
		public void Create(Action<string> callback)
		@{
            serviceDiscovery* impl = [[serviceDiscovery alloc] initWith: callback];
			@{Discovery_iOS:Of(_this)._impl:Set(impl)};
		@}

		[Foreign(Language.ObjC)]
		public void Search()
		@{
			[@{Discovery_iOS:Of(_this)._impl:Get()} search: @"ssdp:all"];
		@}

		public void Dispose()
		{

		}
	}
}