package
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.display.Shape;
    import flash.display.Screen;
    import com.d5power.loader.ResLibParser;
    import com.d5power.bitmapui.D5Style;
    import flash.display.DisplayObject;
    import com.d5power.net.httpd.ASHttpd;
    import flash.filesystem.File;
    import com.d5power.net.HttpDecoder;
    import flash.net.URLRequest;
    import flash.net.URLLoader;
    import flash.events.IOErrorEvent;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;
    import com.d5power.ui.Home;

    [SWF(width="720",height="1600",frameRate="45",backgroundColor="#ffffff")] 
    public class Main extends Sprite
    {
        public function Main()
        {
            this.addEventListener(Event.ADDED_TO_STAGE,this.init)
        }

        private function showPostion():void
        {
            var matcher:D5ScreenMatcher = D5ScreenMatcher.getInstance();
            var s1:Shape = new Shape();
            s1.graphics.beginFill(0xff9900);
            s1.graphics.drawRect(0,0,60,60);
            addChild(s1);

            var s2:Shape = new Shape();
            s2.graphics.beginFill(0xff9900);
            s2.graphics.drawRect(0,0,60,60);
            s2.x = stage.stageWidth - s2.width;
            addChild(s2);

            var s3:Shape = new Shape();
            s3.graphics.beginFill(0xff9900);
            s3.graphics.drawRect(0,0,60,60);
            s3.y = int(D5ScreenMatcher.getInstance().newHeight - s3.height);
            addChild(s3);

            trace("VisibleBounds:",Screen.mainScreen.visibleBounds);
            trace("Bounds:",Screen.mainScreen.bounds);
            //trace("SafeArea",Screen.mainScreen.safeArea);
        }

        private function alliswell(ns:String='',subPath:String = ''):void
        {

            var ui:DisplayObject = new Home;
            this.addChild(ui);

            this.buildInnerService();
        }

        private function buildInnerService():void
        {
            var _httpd:ASHttpd = new ASHttpd(null,'127.0.0.1',60080,'*');
            _httpd.decoder = new HttpDecoder(stage);
            
            // APP 激活时，确保httpd服务生效
            stage.addEventListener(Event.ACTIVATE,function checkHttpStatus(e:Event):void{
                trace("[checkHttpStatus] ACTIVATE... ");
                var b:URLRequest = new URLRequest("http://127.0.0.1:60080/ping");
                var loader:URLLoader = new URLLoader();

                var loading:uint = setTimeout(on_ioerror,2000)

                function on_success(e:Event):void{
                    clearTimeout(loading);
                    loader.removeEventListener(Event.COMPLETE,on_success);
                    loader.removeEventListener(IOErrorEvent.IO_ERROR,on_ioerror);
                    loader.close();
                    loader = null;
                    trace("[checkHttpStatus] ONLINE ");
                }

                function on_ioerror(e:Event=null):void
                {
                    if(e==null)
                    {
                        trace("[checkHttpStatus] Reconnect timeout,restart httpd service in 2 secounds ");
                    }
                    clearTimeout(loading);
                    loader.removeEventListener(Event.COMPLETE,on_success);
                    loader.removeEventListener(IOErrorEvent.IO_ERROR,on_ioerror);
                    _httpd.stop()
                    setTimeout(function():void{
                        trace("[checkHttpStatus] Try to restart httpd service");
                        _httpd.start();
                    },2000);
                    trace("[checkHttpStatus] OFFLINE ");
                }
                loader.addEventListener(Event.COMPLETE,on_success);
                loader.addEventListener(IOErrorEvent.IO_ERROR,on_ioerror);
                loader.load(b);


                trace("[checkHttpStatus] CHECK BEGIN... ");
            });

            stage.addEventListener(Event.DEACTIVATE,function deactive(e:Event):void{
                trace("[checkHttpStatus] DEACTIVATE... ");
            });
            
            _httpd.start();
        }

        private function init(e:Event):void
        {
            // 可选：设置自定义DPI
            D5ScreenMatcher.getInstance(stage);
            this.showPostion();
            D5ScreenMatcher.getInstance().loadFont(function():void{
                var lib:ResLibParser = new ResLibParser('d5ui.res',function():void{
                    D5Style.initUI('ui/uiresource',alliswell,null,null);
                });
            })
            
            
        }
    }
}
