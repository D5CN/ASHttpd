package com.d5power.net.httpd
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.Socket;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.utils.ByteArray;

	[Event(name="complete", type="flash.events.Event")]
	public class HttpContext extends EventDispatcher
	{
		private var _request:HttpRequest;
		private var _response:HttpResponse;
		private var _clientID:String;
		private var _socket:Socket;

		public function HttpContext(socket:Socket,clientID:String)
		{
			this._socket=socket;
			this._clientID=clientID;
			_request=new HttpRequest(_socket);
			_response=new HttpResponse(_socket);
			_request.addEventListener(Event.COMPLETE,request_complete);
		}
		
		private function request_complete(e:Event):void{
			_request.removeEventListener(Event.COMPLETE,request_complete);
			var f:File = ASHttpd.wwwroot.resolvePath(_request.url);
			_response.set_content_type(f.extension);

			var callfun:Function;

			if(f.exists)
			{
				// file exists,try to read it.
				var fs:FileStream = new FileStream();
				fs.open(f,FileMode.READ);
				var b:ByteArray = new ByteArray();
				fs.readBytes(b,0,fs.bytesAvailable);
				this._response.writeBytes(b,0,b.bytesAvailable)
			}else if(ASHttpd.decoder && && ASHttpd.decoder.hasOwnProperty(_request.url) && (callfun = ASHttpd.decoder[_request.url])){
				// no files,but hava same name function in decode,try to run it.
				// if have any error,will return -99
				try
				{
					var data:Object = {};
					data.post = _request.queryString;
					data.file = _request.files;
					data.stream = _request.stream;
					var result:Object = callfun(data);
					if(!result) result = {code:0,data:null,msg:"There are no return value in your decode function."};
					this._response.writeUTFBytes(JSON.stringify(result));
				}catch(err:Error){
					_response.writeUTFBytes(JSON.stringify({code:-99,data:err.getStackTrace()}))
				}
			}else{
				// 404
				this._response.statusCode=404;
			}
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function get request():HttpRequest{return _request;}
		public function get response():HttpResponse{return _response;}
		public function get clientID():String{return _clientID;}
	}
}