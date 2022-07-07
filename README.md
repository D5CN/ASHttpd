# ASHttpd
A http webservice writen by actionscript3

# What ASHttpd can do
start a http server,and allow javascript communicate with actionscript by send post/get data.

# How to use it
- add ASHttpd.swc to your lib path
- Use below code to create a httpserver in port 8080

    var b:ASHttpd = new ASHttpd(File.applicationDirectory.resolvePath('wwwroot'),'127.0.0.1',8080);
    
    var obj:Object = {};
    
    obj.index = function(data:Object):Object
    {
        // you can get data from data.post which sended by browser.
        trace(JSON.stringify(data.post));
        // this return object whill response to browser,so you can get this data in javascript or other language.
        // in broswer you will get data like this:{"data":{msg:"Hello ASHttpd"},"code":0}
        return {msg:"Hello ASHttpd"};
    }

    b.decoder = obj;
    b.start();
    
- [option]create wwwroot directory in your bin-debug path.if this directory not exist,root path will be bin-debug folder.
- complie and run it
- open http://127.0.0.1:8080/index?a=5&b=10 in your browser
- and obj.index function will be called.and you can see what recived in your console.

# Where it from

@chengse66 https://github.com/chengse66/as3-httpserver
