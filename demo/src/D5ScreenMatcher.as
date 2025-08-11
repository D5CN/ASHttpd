package
{
    import flash.display.Stage;
    import flash.display.Screen;
    import flash.display.StageScaleMode;
    import flash.display.StageAlign;
    import flash.display.DisplayObjectContainer;
    import flash.display.DisplayObject;
    import flash.system.Capabilities;
    import flash.geom.Rectangle;
    import com.d5power.core.WebViewAS;
    import com.d5power.FontLoader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import com.d5power.bitmapui.D5Style;
    import flash.text.StageText;
    import flash.geom.Point;
    import com.d5power.bitmapui.D5Text;
    import flash.events.SoftKeyboardEvent;
    import flash.events.EventDispatcher;
    import flash.media.StageWebView;
    /**
     * 屏幕适配，以宽度为标准进行的全屏适配
     * 需要和主程序的舞台尺寸与APP屏幕方向配合使用。
     * 特别说明：如果进行竖屏适配，需要将高度加长，远远高于正常比例，确保横向一定全部显示
     */
    public class D5ScreenMatcher
    {
        /**
         * 根据屏幕比例进行计算得出的原始屏幕宽度
         */
        private static var _originStageWidth:int;
        /**
         * 根据屏幕比例进行计算得出的原始屏幕高度
         */
        private static var _originStageHeight:int;
        /**
         * 屏幕的像素尺寸
         */
        private static var _pixelRext:Rectangle;

        /**
         * 将原始屏幕物理尺寸进行缩放后的标准舞台宽度
         */
        private static var _stageWidth:int;
        /**
         * 将原始屏幕物理尺寸进行缩放后的标准舞台高度
         */
        private static var _stageHeight:int;
        
        /**
         * 同_stageHeight
         */
        private static var _newHeight:int;
        /**
         * 屏幕缩放系数（SWF舞台分辨率/物理分辨率）
         */
        private static var _zoomK:Number;
        /**
         * 是否移动设备
         */
        private static var _isMobile:Boolean;
        /**
         * 对舞台的引用
         */
        private static var _stage:Stage;
        /**
         * UI缩放系数，开发者自由设置。
         */
        private static var _scale:Number=1.0;
        /**
         * 工厂实例
         */
        private static var _instance:D5ScreenMatcher;
        /**
         * 工厂模式
         */
        public static function getInstance(stage:Stage=null):D5ScreenMatcher
        {
            if(!_instance && stage)
            {
                _instance = new D5ScreenMatcher(stage);
            }
            return _instance;
        }

        public function D5ScreenMatcher(stage:Stage):void
        {
            this.updateScale(stage);
        }
        /**
         * 应用舞台宽度，替代原有stage.stageWidth
         */
        public static function get stageWidth():int
        {
            return _stageWidth;
        }
        /**
         * 应用舞台高度，替代原有stage.stageHeight
         */
        public static function get stageHeight():int
        {
            return _stageHeight;
        }

        /**
         * 在StageWebview的边缘弹出界面
         * @target 要弹出的界面
         * @postion 弹出位置
         */
        public function popUpWithWebview(webview:StageWebView,target:DisplayObject,postion:String="R"):void
        {
            postion = postion.toUpperCase();
            if(['R','L','T','B'].indexOf(postion)==-1)
            {
                trace("[Notice] can not support postion "+postion+" in D5ScreenMatcher.popUpWithWebview");
                return;
            }
            var rect:Rectangle = webview.viewPort.clone();
            var targetSize:uint;
            if(postion=="R" || postion=="L"){
                // 由于target是应用内坐标系对象，其尺寸经过整体缩放。而webview是物理分辨率，因此target需要进行缩放后，才能得到相同坐标系的值
                targetSize = Math.ceil(rect.width - target.width*_scale);
            }else{
                // 由于target是应用内坐标系对象，其尺寸经过整体缩放。而webview是物理分辨率，因此target需要进行缩放后，才能得到相同坐标系的值
                targetSize = Math.ceil(rect.height - target.height*_scale);
            }

            var render:Function = function(e:Event):void
            {
                var minvalue:Number;
                var offset:Number;
                if(postion=="R" || postion=="L")
                {
                    offset = (targetSize-rect.width)*.2;
                    rect.width += offset;
                    if(postion=='L')
                    {
                        rect.x -= offset;
                    }
                    minvalue = Math.abs(targetSize-rect.width);
                    if(minvalue<1)
                    {
                        rect.width = targetSize;
                        target.removeEventListener(Event.ENTER_FRAME,render)
                    }
                }else{
                    offset = (targetSize-rect.height)*.2;
                    rect.height += offset;
                    if(postion=='T')
                    {
                        rect.y -= offset;
                    }
                    minvalue = Math.abs(targetSize-rect.height);
                    if(minvalue<1)
                    {
                        rect.height = targetSize;
                        target.removeEventListener(Event.ENTER_FRAME,render)
                    }
                }
                webview.viewPort = rect;
            }
            
            target.addEventListener(Event.ENTER_FRAME,render)
        }

        /**
         * 加载字体
         */
        public function loadFont(callback:Function=null,fontpath:String = 'font.swf'):void
        {
            var loader:FontLoader = new FontLoader( new URLRequest( fontpath ) );
            loader.addEventListener(Event.COMPLETE,function onloaded(e:Event):void{
                var style:D5Style = new D5Style;
                style.default_text_font = '思源黑体 CN Regular';
                loader.removeEventListener(Event.COMPLETE,onloaded);
                if(callback!=null) callback();
            });
        }

        /**
         * 同stageHeight
         */
        public function get newHeight():int
        {
            return _newHeight;
        }

        /**
         * 软键盘弹起适配
         * @target  适配容器
         * @archor  适配目标，一般为输入框或者stageText
         */
        public function softKeybordMatch(target:DisplayObject,archor:Object,k:Number=0.3):D5ScreenMatcher
        {
            var originY:int = target.y;
            var originY_a:Rectangle = archor is StageText ? (archor as StageText).viewPort.clone() : null;
            var offset:int = 0;
            var onKeyboradOpen:Function = function(e:SoftKeyboardEvent):void
            {
                var rect:Rectangle = originY_a==null ? archor.getRect(_stage) : originY_a.clone();
                if(_stage.softKeyboardRect.union(rect))
                {
                    offset = _stageHeight*k - rect.y;//(_stage.softKeyboardRect.height - (_stage.stageHeight - rect.y - rect.height));
                    //trace('stage:',_stageHeight,'keyborad:',_stage.softKeyboardRect,'keyborad after scale:',_stage.softKeyboardRect.height/_scale,'textfield:',rect,"==============");
                    target.y = originY + offset;
                    if(originY_a)
                    {
                        var new_rect:Rectangle = originY_a.clone();
                        new_rect.y+= offset;
                        (archor as StageText).viewPort = new_rect;
                    }
                }
            }

            var onKeyBoradClosed:Function = function(e:SoftKeyboardEvent):void
            {
                target.y = originY;
                if(originY_a) (archor as StageText).viewPort = originY_a;
            }

            var disposeMatch:Function = function(e:Event):void
            {
                archor.removeEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE,onKeyboradOpen);
                archor.removeEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE,onKeyBoradClosed);
                target.removeEventListener(Event.REMOVED_FROM_STAGE,disposeMatch)
            }

            archor.addEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE,onKeyboradOpen);
            archor.addEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE,onKeyBoradClosed);
            target.addEventListener(Event.REMOVED_FROM_STAGE,disposeMatch)
            return this;
        }
        
        /**
         * 使用StageText替换某个D5Text
         */
        public function stageTextRplace(target:D5Text):StageText
        {
            var text:StageText = new StageText();
            var rect:Rectangle = target.getRect(_stage);
            text.stage = _stage;
            text.text = target.text;
            text.fontSize = target.fontSize;
            text.color = target.textColor;
            text.viewPort = rect;
            text.displayAsPassword = target.isPassword;
            text.editable = target.type==1;
            target.parent && target.parent.removeChild(target);
            return text;
        }

        /**
         * 批量居中对齐
         * @param   curr    需要居中对齐的目标
         * @param   offsetX 居中后额外的偏移X
         * @param   offsetY 居中后额外的偏移Y
         */
        public function marginCenter(curr:DisplayObject,offsetX:int=0,offsetY:int=0):D5ScreenMatcher
        {
            var i:uint;
            var j:uint;
            if(curr.hasOwnProperty('width'))
            {
                curr.x = Math.ceil((_stageWidth - curr.width)*.5+offsetX);
                curr.y = Math.ceil((_stageHeight - curr.height)*.5+offsetY);
            }
            return this;
        }

        /**
         * 居右对齐，以数组的第一个元素为目标，相互对齐
         * @param   list    需要居中对齐的目标，其中list[0]是最右侧的对象
         * @param   padding 对齐时的间距
         */
        public function marginRight(list:Array,padding:uint=20):D5ScreenMatcher
        {
            var obj:Object;
            var curr:Object;
            var i:uint;
            var j:uint;

            if(list)
            {
                for(i=0,j=list.length;i<j;i++)
                {
                    curr = list[i];
                    if(!curr || !curr.hasOwnProperty('width')) continue;
                    curr.x = _stageWidth - padding - curr.width;
                    obj = curr;
                    padding+=obj.width;
                }
            }

            return this;
        }

        /**
         * 全屏WebView
         */
        private static var _oldViewPort:Rectangle;
        public function fullScreenWebview(webview:StageWebView):void
        {
            var rect:Rectangle = new Rectangle(0,0,_originStageWidth,_originStageHeight);
            if(!_isMobile)
            {
                zoomViewPort(rect)
            }
            webview.viewPort = rect;
        }

        /**
         * 恢复WebView
         */
        public function normalWebview(webview:WebViewAS):void
        {
            if(!_oldViewPort) return;
            webview.viewPort = _oldViewPort;
        }

        /**
         * 界面尺寸自动适配
         * @param   ui          要进行适配的D5BitmapUI界面，会根据开发者设置的_scale进行整体缩放
         * @param   fullscreen  需要进行自动全屏适配的对象
         * @param   toright     需要进行自动右侧对齐适配的对象
         * @param   tobottom    需要进行自动底部对齐适配的对象
         */
        public function resize(ui:DisplayObjectContainer,fullscreen:Array=null,toright:Array=null,tobottom:Array=null):D5ScreenMatcher
        {
            var obj:Object;
            var i:uint;
            var j:uint;

            if(_scale!=1.0)
            {
                ui.scaleX = ui.scaleY = _scale;
            }

            if(fullscreen)
            {
                for(i=0,j=fullscreen.length;i<j;i++)
                {
                    obj = fullscreen[i];
                    if(!obj || !obj.hasOwnProperty('setSize')) continue;
                    obj.setSize(_stageWidth-obj.x,_stageHeight-obj.y);
                }
            }

            if(toright)
            {
                for(i=0,j=toright.length;i<j;i++)
                {
                    obj = toright[i]
                    if(!obj || !obj.hasOwnProperty('setSize')) continue;
                    obj.setSize(_stageWidth-obj.x,obj.height)
                }
            }

            if(tobottom)
            {
                for(i=0,j=tobottom.length;i<j;i++)
                {
                    obj = tobottom[i]
                    if(!obj || !obj.hasOwnProperty('setSize')) continue;
                    obj.setSize(obj.width,_stageHeight-obj.y)
                }
            }
            return this;
        }

        /**
         * StageWebview视口调整
         */
        private function zoomViewPort(target:Rectangle):void
        {
            if(!target || !_stage) return;
            var zoom:Number = _stage.contentsScaleFactor;
            target.x = int(target.x*zoom)
            target.y = int(target.y*zoom)
            target.width = int(target.width*zoom);
            target.height = int(target.height*zoom);
        }
        
        /**
         * 获取StageWebview的视口
         * @param bindtarget      用于对齐webview视口的对标对象，Webview将和该对象同尺寸同位置
         * @param padding         webview与绑定对象边缘的间距
         */
        public function getWebViewPort(bindtarget:DisplayObject,padding:uint=0):Rectangle
		{
            var rect:Rectangle = new Rectangle(Math.ceil((bindtarget.x+padding)*_scale), Math.ceil((bindtarget.y+padding)*_scale), Math.ceil((bindtarget.width-padding*2)*_scale), Math.ceil((bindtarget.height-padding*2)*_scale));
            if(_isMobile)
            {
                _oldViewPort = rect;
                return rect;
            }else{
                zoomViewPort(rect);
                _oldViewPort = rect;
                return rect;
            }
        }

        /**
         * 适配，一般情况下只需要调用一次
         */
        private function updateScale(stage:Stage):void
        {
            var os:String = Capabilities.os.toLowerCase();
            // 检查 Windows
            if (os.indexOf("win") === 0 || os.indexOf("mac") === 0) {
                stage.scaleMode = StageScaleMode.NO_SCALE;
                _newHeight = stage.stageHeight;
                _zoomK = 1;
                _scale = 1
                _isMobile = false;
            }else{
                stage.scaleMode = StageScaleMode.NO_BORDER;
                _newHeight = stage.stageWidth/(Screen.mainScreen.visibleBounds.width/Screen.mainScreen.visibleBounds.height);
                _zoomK = stage.stageWidth/Screen.mainScreen.visibleBounds.width;
                _scale = 1;
                _isMobile = true;
            }

            stage.align = StageAlign.TOP_LEFT;
            _pixelRext = Screen.mainScreen.visibleBounds.clone();
            _stage = stage;
            _originStageWidth = stage.stageWidth;
            _originStageHeight = _newHeight;

            _stageWidth = Math.ceil(stage.stageWidth/_scale);
            _stageHeight = Math.ceil(_newHeight/_scale);
            trace("updateScale:",_stageWidth,_stageHeight,_originStageWidth,_originStageHeight);

        }
    }
}