package com.d5power.net.httpd
{
	import flash.events.Event;
	
	public class HttpEvent extends Event
	{
		/**
		 * new coming
		 */		
		public static const NEW_CONTEXT:String="newContext";
		/**
		 * BIND_ERR
		 */
		public static const BIND_ERR:String = 'bind_error';

		public static const BIND_SUCCESS:String = 'bin_success';
		
		private var _context:HttpContext;
		
		public function HttpEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function get context():HttpContext{
			return _context;
		}
		
		internal function set_context(m:HttpContext):void{
			this._context=m;
		}
	}
}