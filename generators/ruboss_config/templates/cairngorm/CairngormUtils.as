package com.pomodo.utils {
	
    import com.adobe.cairngorm.control.CairngormEvent;
    
    import mx.controls.Alert;

    public class CairngormUtils {
        public static function dispatchEvent(
            eventName:String, data:Object = null):void
        {
            var event : CairngormEvent =
                new CairngormEvent(eventName);
            event.data = data;
            event.dispatch();
            //var alert:Alert = Alert.show("Well at least the Cairngorm Utils is working..: " + eventName);
        }
    }
}
