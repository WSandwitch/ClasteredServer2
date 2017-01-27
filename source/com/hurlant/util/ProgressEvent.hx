package com.hurlant.util;

import com.hurlant.util.Event;

class ProgressEvent extends Event {
    static public var SOCKET_DATA = "socketData";

    public function new(msg:String) {
        super(msg);
    }
}