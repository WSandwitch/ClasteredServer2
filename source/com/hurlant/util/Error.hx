package com.hurlant.util;

class Error {
    private var msg:String;
    public function new(msg:String) {
        this.msg = msg;
    }
    public function toString() {
        return msg;
    }
}
