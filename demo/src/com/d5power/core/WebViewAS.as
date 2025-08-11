package com.d5power.core
{
    import flash.media.StageWebView;
    import flash.display.Stage;
    import flash.geom.Rectangle;
    import flash.events.DataEvent;

    public class WebViewAS implements IWebView
    {
        protected var _webview:StageWebView;
        protected var _stg:Stage
        public function WebViewAS(stg:Stage)
        {
            this._stg = stg;
            this._webview = new StageWebView({userAgent:"d5power-as3-webview", mediaPlaybackRequiresUserAction:false });
            this._webview.stage = stg;
            this._webview.addEventListener(DataEvent.WEBVIEW_MESSAGE,function(e:DataEvent):void{
                trace("=============================="+e.data);
            })
        }

        public function get webview():StageWebView
        {
            return this._webview
        }

        public function showDevTools():void
        {
            //this._webview.showDevTools();
        }

        public function load(url:String):void
        {
            this._webview.loadURL(url);
        }

        public function callJS(jsname:String,data:Object=null):void
        {
            this._webview.postMessage("Hello")
        }

        public function set visible(v:Boolean):void
        {
            this._webview.stage = v ? this._stg : null;
        }

        public function set viewPort(v:Rectangle):void
        {
            this._webview.viewPort = v;
        }

        public function init(stg:Stage,viewport:Rectangle,url:String):void
        {
            this._webview.viewPort = viewport;
            this._webview.loadURL(url);
        }

        public function dispose():void
        {

        }
    }
}