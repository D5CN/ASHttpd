package  com.d5power.net.httpd
{
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.utils.Dictionary;
	import flash.filesystem.File;
	import flash.utils.setTimeout;

	[Event(name="newContext", type="com.d5power.httpd.HttpEvent")] 
	public class ASHttpd extends EventDispatcher
	{
		protected const RETRY_BIND_TIME:uint = 2000;
		protected var socket:ServerSocket;
		private var cache:Dictionary=new Dictionary(true);
		private static var _wwwroot:File;
		public static function get wwwroot():File
		{
			return _wwwroot;
		}
		

		protected static var _decoder:Object;
		public static function get decoder():Object
		{
			return _decoder;
		}

		protected var _host:String;
		protected var _port:int;
		
		private var _corssdomain:String;
		/**
		 * @param	wwwroot		root path of webservice
		 * @param	host		host address,0.0.0.0 by defalut
		 * @param	port		listen port,60080 by defalut
		 * @param	crossdomain	crossdomain setting,null for now allow cross doamin data loaded.* for allow all doamin loaded.
		 */
		public function ASHttpd(wwwroot:File=null,host:String='0.0.0.0',port:int=60080,crossdomain:String=null)
		{
			socket = new ServerSocket();
			this.wwwroot=wwwroot;
			this._corssdomain = crossdomain;

			this._host = host;
			this._port = port;
		}
		
		/**
		 * 
		 */
		public function listening():Boolean
		{
			return socket && socket.listening;
		}

		public function stop():void
		{
			this.socket.close();
			this.socket = new ServerSocket();
		}

		protected function reBind(host:String=null,port:int = 0):void
		{
			if(host) this._host = host;
			if(port && port>0 && port<65535) this._port = port;
			
			try{
				if(this.socket.bound)
				{
					this.socket.close();
					this.socket = new ServerSocket();
				}
				socket.bind(this._port,this._host);
				socket.addEventListener(ServerSocketConnectEvent.CONNECT,_client_accept);
				socket.listen();
				trace("[ASHttpd] rebind in "+this._host+":"+this._port);
				this.dispatchEvent(new Event(HttpEvent.BIND_SUCCESS))
			}catch(e:Error){
				trace("[ASHttpd] rebind in "+this._host+":"+this._port+" fail. we will try again after "+(RETRY_BIND_TIME*.001)+" seconds");
				setTimeout(reBind,RETRY_BIND_TIME);
				this.dispatchEvent(new Event(HttpEvent.BIND_ERR))
			}
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
		protected function _client_accept(e:ServerSocketConnectEvent):void{
			var context:HttpContext=new HttpContext(e.socket,e.socket.remoteAddress+":"+e.socket.remotePort,this._corssdomain);
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
			this.reBind();
		}
	}
}