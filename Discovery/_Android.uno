using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
    [Require("Gradle.Dependency.Implementation", "com.loopj.android:android-async-http:1.4.9")]
	[ForeignInclude(Language.Java, "com.foreign.Uno.*",
                                   "java.io.IOException",
                                   "android.util.Log")]

	extern(Android)
	internal class Discovery_Android: IDiscovery, IDisposable	
	{
		Java.Object _impl;

		[Foreign(Language.Java)]
		public void Create(Action<string> callback)
		@{
            com.blackcat.serviceDiscovery impl = new com.blackcat.serviceDiscovery(callback);
            @{Discovery_Android:Of(_this)._impl:Set(impl)};
		@}

		[Foreign(Language.Java)]
		public void Search()
		@{
            com.blackcat.serviceDiscovery impl = (com.blackcat.serviceDiscovery)@{Discovery_Android:Of(_this)._impl:Get()};
            impl.search("ssdp:all");
		@}

		public void Dispose()
		{

		}
	}
}

