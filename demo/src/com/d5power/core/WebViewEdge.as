package com.d5power.core
{
    import flash.media.StageWebView;
    import flash.display.Stage;
    import flash.geom.Rectangle;
    import flash.events.ErrorEvent;
    import flash.system.Capabilities;

    public class WebViewEdge implements IWebView
    {
		private var _webview:StageWebView;
        private var _stg:Stage
        public function WebViewEdge(stg:Stage)
        {
            this._stg = stg;
            var isDebugger:Boolean = Capabilities.isDebugger;

            var conf:Object = {
                mediaPlaybackRequiresUserAction: false
            }
            this._webview = new StageWebView(conf);
            this._webview.stage = stg;
            this._webview.addEventListener(ErrorEvent.ERROR,onErrorEvent);
        }

        private function onErrorEvent(event : ErrorEvent) : void
        {
            trace("[ErrorEvent]Error loading URL: " + event.toString() + " (ID " + event.errorID + ") - Text: " + event.text);
        }

        public function showDevTools():void
        {
            //this._webview.showDevTools();
        }

        public function load(url:String):void
        {
            trace("[WebviewEdge Load Begin] "+url);
            this._webview.loadURL(url);
        }

        public function callJS(jsname:String,data:Object=null):void
        {
            this._webview.loadURL("javascript:"+jsname+(data ? data : '()'));
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
            trace("[WebviewEdge init with url] "+url);
            this._webview.viewPort = viewport;
            this._webview.loadURL(url);
        }

        public function dispose():void
        {

        }
	}
}