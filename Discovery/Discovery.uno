using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace BlackCat
{
	internal interface IDiscovery
	{
		void Create(Action<string> callback);
		void Search();
	}

	internal class Discovery_Stub: IDiscovery
	{
        public void Create(Action<string> callback) {}
		public void Search() {}
	}

	public class Discovery
	{
		readonly IDiscovery _impl;

		public Action<string> Callback;

		public Discovery()
		{
			if defined(Android)
			{
				_impl = new Discovery_Android();
			}
			else if defined(iOS)
			{
				_impl = new Discovery_iOS();
			} 
			else 
			{
				_impl = new Discovery_Stub();
			}

            _impl.Create(_Callback);
		}

		public void Search()
		{
			_impl.Search();
		}

        void _Callback(string list)
		{
			if (Callback != null)
				Callback(list);
		}
    }
}
