# ASHttpd
A http webservice and Websocket service writen by actionscript3

Support PC\MAC\Andorid\iOS

# What ASHttpd can do
start a http server,and allow javascript communicate with actionscript by send post/get data.

It also support websocket,now your html file can connect to AS websocket server,and the same way to call AS Function

# How to use it with websocket
- add ASHttpd.swc to your lib path
- Use below code to create a websocket server in port 8081 (default port is 60081)
        
        var ws:ASWebsocket = new ASWebsocket('0.0.0.0',60081);
        var obj:Object = {};
    
        obj.ping = function(data:Object):Object{ return {data:pong}; }
        
        ws.start();
        ws.decoder = obj;
  

Now,you can connect to this server with JS or other code.and if you push message {"do":"ping"} to server,the function ping in AS3 will called.and you will got message '{"data":"pong"}' in your client.

If you wantna transfer params to AS,you can push them in data param.just like this {"do":"ping","data":{"a":10}}. Then in function ping in AS3,you can read it from data.

    var obj:Object = {};
    obj.ping = function(data:Object):Object{
    
        trace(data.a);
        
        return {data:pong};
    }

    

# How to use it with http 
- add ASHttpd.swc to your lib path
- Use below code to create a httpserver in port 8080 (defualt port is 60080)
    

    var b:ASHttpd = new ASHttpd(File.applicationDirectory.resolvePath('wwwroot'),'0.0.0.0',8080);
    
    var obj:Object = {};
    
    obj.index = function(data:Object):Object
    {
    
        // you can get POST data from data.post which sended by browser.NOTICE: if there are no POST data,data.post will get GET data
        
        trace(JSON.stringify(data.post));
        
        // you can get GET data from data.get which sended by browser.
        trace(JSON.stringify(data.get));
        
        // this return object will response to browser,so you can get this data in javascript or other language.
        
        // in broswer(or ajax request) you will get data like this:{"data":{msg:"Hello ASHttpd"},"code":0}
        
        return {msg:"Hello ASHttpd"};
        
    }

    b.decoder = obj;
    
    b.start();


- [option]create wwwroot directory in your bin-debug path.if this directory not exist,root path will be bin-debug folder.
- complie and run it
- open http://127.0.0.1:8080/index?a=5&b=10 in your browser
- and obj.index function will be called.and you can see what recived in your console.

# Cross domain support
If you need your server can be loaded by cross domain request,Please use blow code:
    
    var b:ASHttpd = new ASHttpd(File.applicationDirectory.resolvePath('wwwroot'),'127.0.0.1',8080,'*'); // allow all request
    
    var b:ASHttpd = new ASHttpd(File.applicationDirectory.resolvePath('wwwroot'),'127.0.0.1',8080),'*.d5power.com'); // allow request from *.d5power.com
    
    
# Allow connection from Other IP address
In default,ASHttp can just allow request from localhost/127.0.0.1,if you need your sever allow connection from other ip address,please use 0.0.0.0 to init your server.just like this:
    
    var b:ASHttpd = new ASHttpd(File.applicationDirectory.resolvePath('wwwroot'),'0.0.0.0',8080),'*.d5power.com'); // allow request from *.d5power.com
    
# Where it from

@chengse66 https://github.com/chengse66/as3-httpserver
@childoftv https://github.com/childoftv/as3-websocket-server
