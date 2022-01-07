package com.d5power.net.httpd
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public dynamic class HttpFile
	{
		public var name:String;
		public var filename:String;
		public var contentType:String;
		public var tmpFile:String;
		private var _size:int=-1;
		public function HttpFile()
		{
			
		}
		
		/**
		 * 当前文件的大小尺寸 
		 * @return 
		 */		
		public function get size():uint{
			if(_size==-1){
				var file:File=new File(tmpFile);
				if(file.exists){
					var fs:FileStream=new FileStream();
					fs.open(file,FileMode.READ);
					_size=fs.bytesAvailable;
					fs.close();
				}
			}
			return _size;
		}
	}
}