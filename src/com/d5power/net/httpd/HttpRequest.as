package com.d5power.net.httpd
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.IDataOutput;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	[Event(name="complete", type="flash.events.Event")]
	public class HttpRequest extends EventDispatcher
	{
		public static var DEFAULT_FILE:String = 'index.html';
		public static const TEXT_PLAIN:String="text/plain";
		public static const TEXT_HTML:String="text/html";
		public static const APPLICATION_X_WWW_FORM_URLENCODED:String="application/x-www-form-urlencoded";
		public static const MULTIPART_FORM_DATA:String="multipart/form-data";
		public static const APPLICATION_OCTET_STREAM:String="application/octet-stream";
		public static const CONTENT_LENGTH:String="Content-Length";
		public static const CONTENT_TYPE:String="Content-Type";
		
		private const REG_ENCODEURL:RegExp =/([\w\d\.\/\:]+)\=([\w\d\%\.\/\:]+)/g;
		private const REG_URL:RegExp=/\?.*+$/g;
		private const REG_LINE:RegExp=/^[\w\d\-]+/;
		private const REG_KEYPAIR:RegExp=/\w+\=\"[^"]+\"/g;

		//对外属性
		public var url:String;
		public var rawURL:String;
		public var method:String;
		public var version:String;
		public var header:Object={};
		public var contentLength:int=0;
		public var contentType:String=TEXT_HTML;
		public var queryString:Object={};
		public var post:Object={};
		public var files:Object={};
		
		private var sr:HttpRequestReader;
		private var _timeout:int;
		private var data:HttpFile=new HttpFile();
		private var sw:IDataOutput;
		private var state:int=0;
		private var CLRF:Boolean=false;
		private var boundary:String;
		private var tmps:Array=[];
		private var socket:Socket;
		private var _buffer:ByteArray=new ByteArray();
		private var _hasPost:Boolean = false;
		
		public function HttpRequest(socket:Socket)
		{
			this.socket=socket;
			this.socket.addEventListener(ProgressEvent.SOCKET_DATA,reader_header);
			sr=new HttpRequestReader(socket);
			this.reset_clock();
		}

		public function get hasPost():Boolean
		{
			return _hasPost;
		}
		
		/**
		 * 重置时钟
		 */		
		private function reset_clock():void{
			clearTimeout(_timeout);
			_timeout=setTimeout(reader_end,1000);
		}
		
		/**
		 * 数据接收 
		 * @param e
		 */		
		private function reader_header(...args):void{
			this.reset_clock();
			var line:String;
			while(socket.connected  && sr.readLine()){
				line=sr.buffer.toString();
				if(line!=""){
					parse_header_line(line);
				}else{
					parse_header_end();
					socket.removeEventListener(ProgressEvent.SOCKET_DATA,reader_header);
					var checker:int = contentType.indexOf(';');
					if(checker!=-1)
					{
						contentType = contentType.substring(0,checker);
					}
					switch(contentType){
						case TEXT_HTML:
						case TEXT_PLAIN:
							reader_end();
							break;
						case APPLICATION_X_WWW_FORM_URLENCODED:
							_buffer.clear();
							sr.byteReaded=0;
							socket.addEventListener(ProgressEvent.SOCKET_DATA,reader_post);
							reader_post();
							break;
						case MULTIPART_FORM_DATA:
							sr.byteReaded=0;
							socket.addEventListener(ProgressEvent.SOCKET_DATA,reader_form_data);
							reader_form_data();
							break;
						case APPLICATION_OCTET_STREAM:
							_buffer.clear();
							sr.byteReaded=0;
							socket.addEventListener(ProgressEvent.SOCKET_DATA,reader_octet_stream);
							reader_octet_stream();
							break;
					}
					break;
				}
			}
		}
		
		/**
		 * 解析 APPLICATION_X_WWW_FORM_URLENCODED
		 */		
		private function reader_post(...args):void{
			this.reset_clock();
			sr.readLine();
			trace("==================",sr.buffer.toString());
			if (sr.byteReaded >= contentLength) {
				socket.removeEventListener(ProgressEvent.SOCKET_DATA, reader_post);
				
				parse_url_data(sr.buffer.toString(),post);
				reader_end();
			}
		}
		
		
		/**
		 * 解析 MULTIPART_FORM_DATA
		 * @param args
		 */		
		private function reader_form_data(...args):void{
			var text:String,i:int,b:int,a:String,readFlag:Boolean=true;
			while(true){
				readFlag=sr.readLine();
				if(!readFlag) break;
				if(state==0){
					if(sr.buffer.length>=this.boundary.length){
						text=sr.buffer.toString();
						if(text.indexOf(this.boundary)>=0){
							state=1;
						}
					}
				}else if(state==1){
					//解析Header
					text=sr.buffer.toString();
					if(text.indexOf("Content-Disposition: form-data; ")==0){
						data=new HttpFile();
						var sps:Array=text.match(REG_KEYPAIR);
						for(i=0;i<sps.length;i++){
							a=sps[i].replace(/[\'\"]/g,"");
							b=a.indexOf("=");
							if(b>0) data[a.substring(0,b)]=a.substring(b+1);
						}
					}else if(text.indexOf("Content-Type: ")==0){
						data.contentType=text.replace("Content-Type: ","");
					}else if(text==""){
						if(data.filename){
							var nf:File=requireTmp();
							data.tmpFile=nf.nativePath;
							var fs:FileStream=new FileStream();
							fs.open(nf,FileMode.APPEND);
							sw=fs;
						}else{
							_buffer.clear();
							sw=_buffer;
						}
						CLRF=false;
						state=2;
					}
				}else if(state==2){
					if(sr.buffer.length<=this.boundary.length+10 && sr.buffer.length>=this.boundary.length && sr.buffer.toString().indexOf(this.boundary)>=0){
						if(sw is FileStream){
							(sw as FileStream).close();
							this.files[data.name]=data;
						}else{
							this._hasPost = true;
							this.post[data.name]=_buffer.toString();
						}
						state=1;
					}else{
						if(CLRF){
							sw.writeByte(13);
							sw.writeByte(10);
						}
						sw.writeBytes(sr.buffer,0,sr.buffer.length);
						CLRF=true;
					}
				}
			}
			if(sr.byteReaded==contentLength){
				socket.removeEventListener(ProgressEvent.SOCKET_DATA,reader_form_data);
				_buffer.clear();
				reader_end();
			}
		}
		
		/**
		 * 读取二进制流数据 
		 */		
		private function reader_octet_stream(...args):void{
			socket.readBytes(_buffer,_buffer.length,socket.bytesAvailable);
			if(_buffer.length>=contentLength){
				reader_end();
			}
		}
		
		/**
		 * 流程处理结束 
		 */		
		private function reader_end():void{
			clearTimeout(_timeout);
			sr.dispose();
			if(url==null || rawURL==null){
				try{
					socket.close();
				}catch(e:Error){
				}
			}else{
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
			this._buffer.clear();
			this.dispose();
		}
		
		/**
		 * 清空当前文件 
		 */		
		private function dispose():void{
			for(var i:int=0;i<this.tmps.length;i++){
				var f:File=new File(this.tmps[i]);
				if(f.exists){
					try{
						f.deleteFileAsync();
					}catch(e:Error){
						
					}
				}
			}
		}
		
		/**
		 * 处理文件头 
		 */		
		private function parse_header_end():void{
			if(header[CONTENT_LENGTH]){
				contentLength=int(header[CONTENT_LENGTH]);
			}else{
				contentLength=1024*512;
			}
			if(header[CONTENT_TYPE]){
				var _l:Array=header[CONTENT_TYPE].split('; boundary=');
				if(_l.length==2){
					contentType=_l[0];
					boundary=_l[1];	
				}else{
					contentType=header[CONTENT_TYPE];
				}
			}
		}
		
		/**
		 * 当前输入的流仅 octet stream 有效
		 * @return 
		 * 
		 */		
		public function get stream():ByteArray{
			return _buffer;
		}
		
		/**
		 * 处理头部 
		 * @param text
		 * 
		 */		
		private function parse_header_line(text:String):void{
			var a:Object=text.match(REG_LINE);
			if(a.length!=1 || a.index!=0) return;
			var b:String=String(a[0]).toLowerCase();
			if(b=="post" || b=="get"){
				//第一行
				var c:Array=text.split(/\s+/);
				if(c.length==3){
					method=c[0];
					rawURL=c[1];
					version=c[2];

					rawURL=rawURL && rawURL!='/' ? rawURL : DEFAULT_FILE;
					url=rawURL.replace(REG_URL,"");
					url=url.length>0 ? url.substr(1) : DEFAULT_FILE;
					
					parse_url_data(rawURL,queryString);
				}
			}else{
				var poz:int=text.indexOf(": ");
				if(poz>0) header[text.substring(0,poz)]=text.substring(poz+2);
			}
		}
		
		/**
		 * 处理字符post get数据 
		 * @param text
		 * @param data
		 * 
		 */			
		private function parse_url_data(text:String,data:Object):void{
			REG_ENCODEURL.lastIndex = 0;
			var list:Array = REG_ENCODEURL.exec(text);
			
			while (list != null) {
				if(data===queryString){
					data[list[1]] =unescape(list[2]);
				}else{
					this._hasPost = true;
					try{
						data[list[1]] = decodeURIComponent(list[2]); 
					}catch(e:Error){
						data[list[1]] = unescape(list[2]); 
					}
				}
				list = REG_ENCODEURL.exec(text);
			}
		}
		
		/**
		 * 请求一个临时文件 
		 * @return 
		 */		
		private function requireTmp():File{
			var f:File= new File(File.createTempFile().nativePath);
			tmps.push(f.nativePath);
			trace(f.nativePath);
			return f;
		}
	}
}