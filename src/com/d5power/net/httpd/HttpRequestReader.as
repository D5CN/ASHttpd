package com.d5power.net.httpd
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;

	internal class HttpRequestReader
	{
		private var ms:IDataInput;
		private var mb:ByteArray;
		private var crlf:Boolean;
		public var byteReaded:int=0;
		public function HttpRequestReader(stream:IDataInput)
		{
			this.ms=stream;	
			mb=new ByteArray();
		}
		
		/**
		 * Try to read hole line data
		 * @return wether read process is complete
		 */		
		public function readLine():Boolean{
			if(crlf){
				mb.clear();
				crlf=false;
			}
			var b:int;
			while(ms.bytesAvailable>0){
				b = ms.readByte(); 
				byteReaded++;
				if(b!=13){
					buffer.writeByte(b);
				}else{
					if(ms.bytesAvailable>0){
						b = ms.readByte();
						byteReaded++;
						if(b!=10){
							buffer.writeByte(13);
							buffer.writeByte(b);
						}else{
							crlf=true;
							break;
						}
					}
				}
			}
			return crlf;
		}
		
		/**
		 *  
		 */		
		public function dispose():void{
			buffer.clear();
		}
		
		/**
		 * buffer
		 * @return 
		 */		
		public function get buffer():ByteArray{
			return mb;
		}
	}
}