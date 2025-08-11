package com.d5power.core
{
    import flash.geom.Rectangle;
    import flash.display.Stage;

    public interface IWebView
    {
        function showDevTools():void;
        function load(url:String):void;
        function callJS(jsname:String,data:Object=null):void
        function set visible(v:Boolean):void;
        function set viewPort(v:Rectangle):void;
        function init(stg:Stage,viewport:Rectangle,url:String):void;
        function dispose():void;
    }
}