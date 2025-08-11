package com.d5power.net
{
    import flash.display.Stage;

    public dynamic class HttpDecoder
    {
        private var _stage:Stage;
        public function HttpDecoder(stg:Stage):void
        {
            this._stage = stg;
        }

        public function stopServer():void
        {

        }

        public function ping(data:Object):Object
        {
            return {data:"pong"}
        }

        public function debug(data:Object):Object
        {
            return {POST:data.post,GET:data.get};
        }
    }
}