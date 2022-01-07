package  com.d5power.net.httpd
{
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.utils.Dictionary;
	import flash.filesystem.File;

	[Event(name="newContext", type="com.d5power.httpd.HttpEvent")] 
	public class ASHttpd extends EventDispatcher
	{
		private var socket:ServerSocket;
		private var cache:Dictionary=new Dictionary(true);
		private static var _wwwroot:File;
		public static function get wwwroot():File
		{
			return _wwwroot;
		}
		

		private static var _decoder:Object;
		public static function get  decoder():Object
		{
			return _decoder;
		}
		
		/**
		 * @param	wwwroot		root path of webservice
		 * @param	host		host address,127.0.0.1 by defalut
		 * @param	port		listen port,60080 by defalut
		 */
		public function ASHttpd(wwwroot:File=null,host:String='127.0.0.1',port:int=60080)
		{
			socket=new ServerSocket();
			socket.addEventListener(ServerSocketConnectEvent.CONNECT,_client_accept);
			socket.bind(port,host);
			this.wwwroot=wwwroot;
		}

		/**
		 * set your root path of webservice
		 */
		public function set wwwroot(f:File):void
		{
			if(f && f.isDirectory)
			{
				_wwwroot = f;
			}else{
				//_wwwroot = File.applicationStorageDirectory;
				_wwwroot = File.applicationDirectory;
			}
		}

		/**
		 * Set your http decoder for webservice
		 * If file path which sended by request can not find in root path,
		 * the programe will try to find the function in decoder,and transmit post and get vars to this function
		 * function in decoder need a param to recive a object data which contains get and post param.
		 */
		public function set decoder(v:Object):void
		{
			_decoder = v;
		}
		
		/**
		 * Connected to client
		 * @param e
		 */		
		private function _client_accept(e:ServerSocketConnectEvent):void{
			var context:HttpContext=new HttpContext(e.socket,e.socket.remoteAddress+":"+e.socket.remotePort);
			context.addEventListener(Event.COMPLETE,context_complete);
		}
		
		/**
		 * request process complete 
		 * @param e
		 * 
		 */		
		private function context_complete(e:Event):void{
			var context:HttpContext=e.target as HttpContext;
			context.removeEventListener(Event.COMPLETE,context_complete);
			var h:HttpEvent=new HttpEvent(HttpEvent.NEW_CONTEXT);
			h.set_context(context);
			this.dispatchEvent(h);
			context.response.flush();
		}
		
		/**
		 * start 
		 */		
		public function start():void{
			socket.listen();
		}
	}
}