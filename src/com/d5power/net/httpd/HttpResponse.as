package com.d5power.net.httpd
{
	import flash.net.Socket;
	import flash.utils.ByteArray;

	public class HttpResponse extends ByteArray
	{
		private var socket:Socket;
		public var header:Object={};
		public var statusCode:int=200;
		public var contentType:String="text/html";
		
		public function HttpResponse(socket:Socket)
		{
			this.socket=socket;	
		}
		
		/**
		 * get status code 
		 * @param code
		 */		
		private function get_status_name(code:uint):String{
			var text:String="OK";
			switch(code){
				case 200:
					text="OK";
					break;
				case 403:
					text="Forbidden";
					break;
				case 404:
					text="Not Found";
					break;
				case 500:
				default:
					text="Internal Server Error";
					break;
			}
			return code+" "+text;
		}
		
		/**
		 * get contentType by request file extendsion.
		 * @param extension File extension,WITHOUT '.'
		 * @return 
		 */		
		public function set_content_type(extension:String=""):String{
			extension=extension ? extension.toLowerCase() : 'html';
			switch(extension){
				case "xml":
				case "xquery":
				case "xq":
				case "xsl":
				case "xql":
				case "xsd":
				case "xslt":
					extension="text/xml";
					break;
				case "xls":
					extension="application/x-xls";
					break;
				case "txt":
				case "log":
					extension="text/plain";
					break;
				case "html":
				case "htm":
				case "htx":
				case "jsp":
				case "php":
				case "stm":
				case "xhtml":
					extension="text/html";
					break;
				case "tif":
					extension="image/tiff";
					break;
				case "gif":
					extension="image/gif";
					break;
				case "png":
					extension="image/png";
					break;
				case "jpg":
				case "jpeg":
				case "jfif":
				case "jpe":
					extension="image/jpeg";
					break;
				default:
					extension="application/octet-stream";
					break;
			}
			contentType = extension;
			return extension;
		}
		
		/**
		 * Output content
		 */		
		public function flush():void{
			if(socket.connected){
				socket.writeUTFBytes("HTTP/1.1 "+get_status_name(statusCode)+"\r\n");
				socket.writeUTFBytes("Content-Type: "+contentType+"\r\n");
				socket.writeUTFBytes("Content-Length:"+this.length+"\r\n");
				for(var i:Object in header) socket.writeUTFBytes(i+": "+String(header[i])+"\r\n");
				socket.writeUTFBytes("\r\n");
				socket.writeBytes(this,0,this.length);
				socket.flush();
				socket.close();
				this.clear();
			}
		}
	}
}