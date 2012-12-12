package com.wighawag.p2p;

class MessageWrap {
    public var message(default,null) : Dynamic;
    public var timestamp(default,null) : Float;
    public var messageType(default, null) : String;

    public function new(message : Dynamic, messageType : String, timestamp : Float){
        this.message = message;
        this.timestamp = timestamp;
        this.messageType = messageType;
    }

    public static function parse(dyn : Dynamic) : MessageWrap{
        return new MessageWrap(dyn.message, dyn.messageType, dyn.timestamp);
    }
}

