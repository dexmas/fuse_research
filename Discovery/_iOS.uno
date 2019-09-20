using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
    [Require("Xcode.Framework", "Foundation.framework")]
	[ForeignInclude("Language.ObjC", "serviceDiscovery.h")]

	extern(iOS)
	internal class Discovery_iOS: IDiscovery, IDisposable	
	{
		ObjC.Object _impl;

		[Foreign(Language.ObjC)]
		public void Create(Action<string> callback)
		@{
            impl = [[serviceDiscovery alloc] create: callback];
		@}

		[Foreign(Language.ObjC)]
		public void Search()
		@{
            [@{Discovery_iOS:Of(_this)._impl:Get()} search];
		@}

		public void Dispose()
		{

		}
	}
}