package com.d5power.net.httpd
{
    import flash.events.ServerSocketConnectEvent;
    import flash.net.Socket;
    import com.d5power.net.websocket.ClientEntry;
    import flash.utils.Dictionary;
    import flash.events.ProgressEvent;
    import flash.events.Event;
    import flash.utils.ByteArray;
    import com.adobe.crypto.SHA1
    import flash.net.ServerSocket;

    public class ASWebsocket extends ASHttpd
    {
        public static const WEB_SOCKET_MAGIC_STRING:String="258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
        private static const RETRY_BIND_TIME:uint=2000;

        protected var clientDict:Dictionary=new Dictionary();

        /**
		 * @param	wwwroot		root path of webservice
		 * @param	host		host address,0.0.0.0 by defalut
		 * @param	port		listen port,60080 by defalut
		 */
		public function ASWebsocket(host:String='0.0.0.0',port:int=60081)
		{
			socket = new ServerSocket();
			this._host = host;
			this._port = port;
		}

		public function broadcast(msg:String):void
		{
			for(var key:* in clientDict)
			{
				if(key is String)
				{
					try{
						var clientSocket:Socket=(clientDict[key] as ClientEntry).socket;
						sendto(clientSocket,msg);
					}
					catch ( error:Error )
					{
						log( error.message );
					}
				}
			}
		}
		
		public function sendto(clientSocket:Socket,msg:String,continuation:Boolean=false):void
		{
			if( clientSocket != null && clientSocket.connected )
			{
				var rawData:ByteArray=new ByteArray()
				var indexStartRawData:uint;
				rawData.writeUTFBytes( msg );
				rawData.position=0;
				var bytesFormatted:Array=[];
				
				if(continuation)
				{
					bytesFormatted[0] = 128;
				}else{
					//Text Payload
					bytesFormatted[0] = 129; 
				}
				
				if (rawData.length <= 125)
				{
					bytesFormatted[1] = rawData.length;
					
					//indexStartRawData = 2;
				}else if(rawData.length >= 126 && rawData.length <= 65535){
					
					
					bytesFormatted[1] = 126
					bytesFormatted[2] = ( rawData.length >> 8 ) & 255
					bytesFormatted[3] = ( rawData.length) & 255
					
					//indexStartRawData = 4
				}else{
					bytesFormatted[1] = 127
					bytesFormatted[2] = ( rawData.length >> 56 ) & 255
					bytesFormatted[3] = ( rawData.length >> 48 ) & 255
					bytesFormatted[4] = ( rawData.length >> 40 ) & 255
					bytesFormatted[5] = ( rawData.length >> 32 ) & 255
					bytesFormatted[6] = ( rawData.length >> 24 ) & 255
					bytesFormatted[7] = ( rawData.length >> 16 ) & 255
					bytesFormatted[8] = ( rawData.length >>  8 ) & 255
					bytesFormatted[9] = ( rawData.length       ) & 255
					
					//indexStartRawData = 10;
				}
				
				// put raw data at the correct index
				var dataOut:ByteArray=new ByteArray();
				
				for(var i:uint=0;i<bytesFormatted.length;i++)
				{
					dataOut.writeByte(bytesFormatted[i]);
				}
				
				dataOut.writeBytes(rawData);
				dataOut.position=0;
				clientSocket.writeBytes(dataOut);
				clientSocket.flush(); 
				log( "Sent message to "+getClientKeyBySocket(clientSocket)+" msg="+msg);
			}else{
				log("No socket connection.");
			}
		}
		
		private function log( text:String ):void
		{
			trace( text );
		}

        override protected function _client_accept(e:ServerSocketConnectEvent):void
        {
			trace("Ready for connect");
            if(e.socket.remotePort!=0)
			{
				var clientSocket:Socket=registerClient(e.socket).socket;
				clientSocket.addEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData );
				clientSocket.addEventListener(Event.CLOSE,handleSocketClose);
				trace( "Connection from address: "+ getClientKeyBySocket(clientSocket));
				
				dispatchEvent(new ClientEvent(ClientEvent.CLIENT_CONNECT_EVENT,clientSocket));
			}
        }

        protected function handleSocketClose(event:Event):void
		{
			var clientSocket:Socket=event.currentTarget as Socket;
			clientSocket.removeEventListener( ProgressEvent.SOCKET_DATA, onClientSocketData );
			clientSocket.removeEventListener(Event.CLOSE,handleSocketClose);
			var oldKey:String=unregisterClient(clientSocket);
			dispatchEvent(new ClientEvent(ClientEvent.CLIENT_DISCONNECT_EVENT,clientSocket,oldKey+" disconnected"));
		}

        private function unregisterClient(clientSocket:Socket):String
		{
			var location:String;
			
			if(clientDict[clientSocket]){
				var ce:ClientEntry=clientDict[clientSocket] as ClientEntry;
				location=ce.key;
				ce.dispose();
				clientDict[clientSocket]=null;
				delete clientDict[clientSocket];
				clientDict[location]=null;
				delete clientDict[location];
			}
			return location;
		}

        private function getClientEntryBySocket(socket:Socket):ClientEntry
		{
			return clientDict[getClientKeyBySocket(socket)];
		}

        private function onClientSocketData( event:ProgressEvent ):void
		{
			var socket:Socket=event.currentTarget as Socket;
			var clientEntry:ClientEntry=getClientEntryBySocket(socket);
			var clientSocket:Socket=clientEntry.socket;
			if (!clientEntry.handshakeDone){
				//trace("======= handshake ===== ");
				doHandShake(clientSocket,clientEntry);
			}else{
				//trace("======= readmessage ===== ");
				readMessage(clientSocket);
			}
		}

        private function applyMask(mask:ByteArray,byte:int,index:uint):int
		{
			mask.position=index % 4;
			var maskByte:int=mask.readByte();
			
			return byte ^ maskByte;
		}

        private function doHandShake(clientSocket:Socket,clientEntry:ClientEntry):void
		{
			var socketBytes:ByteArray = new ByteArray();
			clientSocket.readBytes(socketBytes,0,clientSocket.bytesAvailable);
			var message:String = socketBytes.readUTFBytes(socketBytes.bytesAvailable);
			//log(message);
			
			clientEntry.handshakeDone=true;
			var i:uint = 0;
			if(message.indexOf("GET ") == 0)
			{
				var messageLines:Array = message.split("\n");
				var fields:Object = {};
				var requestedURL:String = "";
				for(i = 0; i < messageLines.length; i++)
				{
					var line:String = messageLines[i];
					if(i == 0)
					{
						var getSplit:Array = line.split(" ");
						if(getSplit.length > 1)
						{
							requestedURL = getSplit[1];
						}
					}
					else
					{
						var index:int = line.indexOf(":");
						if(index > -1)
						{
							var key:String = line.substr(0, index);
							fields[key] = line.substr(index + 1).replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2" );
						}
					}
				}
				
				if(fields["Sec-WebSocket-Key"] != null)
				{
					
					var joinedKey:String=fields["Sec-WebSocket-Key"]+WEB_SOCKET_MAGIC_STRING;
					
					//hash it
					var base64hash:String = SHA1.hashToBase64(joinedKey);
					var response:String = "HTTP/1.1 101 Switching Protocols\r\n" +
						"Upgrade: WebSocket\r\n" +
						"Connection: Upgrade\r\n" +
						"Sec-WebSocket-Accept: "+base64hash+"\r\n"+
						"Sec-WebSocket-Origin: " + fields["Origin"] + "\r\n" +
						"Sec-WebSocket-Location: ws://" + fields["Host"] + requestedURL + "\r\n" +
						"\r\n";
					var responseBytes:ByteArray = new ByteArray();
					responseBytes.writeUTFBytes(response);
					responseBytes.position = 0;
					clientSocket.writeBytes(responseBytes);
					clientSocket.flush();
					socketBytes.clear();
				}
			}
		}

        private function readMessage(clientSocket:Socket):void
		{
			
			/*var policy_file = '<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>';
			clientSocket.writeUTFBytes(policy_file);
			clientSocket.flush();*/
			var buffer:ByteArray = new ByteArray();
			var outBuffer:ByteArray=new ByteArray();
			var mask:ByteArray=new ByteArray();
			
			//discard for now
			var typeByte:int=clientSocket.readByte();
			
			var byteTwo:int=clientSocket.readByte() & 127;
			//trace("byteTwo ",byteTwo);
			
			var sizeArray:ByteArray=new ByteArray();
			
			if(byteTwo==126)
			{
				//large frame size, 2 more frame size bytes
				clientSocket.readBytes(sizeArray,0,2);
			}else if(byteTwo==127)
			{
				//larger frame size (8 more frame size bytes)
				clientSocket.readBytes(sizeArray,0,8);
			}
			//Read the mask bytes
			clientSocket.readBytes(mask,0,4);
			
			//Copy payload data into buffer
			clientSocket.readBytes(buffer,0,clientSocket.bytesAvailable);
			buffer.position=0;
			var len:uint=buffer.bytesAvailable;
			for(var j:uint=0;j<len;j++)
			{
				//unmask buffer data into output buffer
				outBuffer.writeByte(applyMask(mask,buffer.readByte(),j));
			}
			outBuffer.position=0;
			var msg:String=outBuffer.readUTFBytes(outBuffer.bytesAvailable);
			//trace("======= "+msg+" ===== ");
			try
			{
				var obj:Object = JSON.parse(msg);
				var do_code:String = obj['do'];
				if(do_code && _decoder.hasOwnProperty(do_code))
				{
					var result:Object = _decoder[do_code](obj);
					if(result)
					{
						this.sendto(clientSocket,JSON.stringify(result));
					}
				}else{
					dispatchEvent(new ClientEvent(ClientEvent.CLIENT_MESSAGE_EVENT,clientSocket,msg));
				}
			}catch(e:Error){
				trace(e.getStackTrace()+"\n"+e.message);
				dispatchEvent(new ClientEvent(ClientEvent.CLIENT_MESSAGE_EVENT,clientSocket,msg));
			}
			
		}

        private function registerClient(socket:Socket):ClientEntry
		{
			var key:String=getClientKeyBySocket(socket);
			trace("register client: "+key);
			var client:ClientEntry;
			if(clientDict[key])
			{
				client=clientDict[key];
			}else{
				client=new ClientEntry(key,socket);
				clientDict[getClientKeyBySocket(socket)]=client;
				clientDict[client.socket]=client;
			}
			return client;
		}

        private function getClientKeyBySocket(socket:Socket):String
		{
			return socket.remoteAddress+":"+socket.remotePort;
		}
    }
}