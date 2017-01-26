package com.hurlant.crypto.encoding;

import com.hurlant.util.ByteArray;
import haxe.io.Bytes;
class ASCII implements Charset {
    public function new() {
    }

    public function encode(input:String):Bytes {
        var out = new ByteArray();
        for (n in 0 ... input.length) out.writeByte(input.charCodeAt(n));
        return out;
    }

    public function decode(bytes:Bytes):String {
        var out = '';
        for (n in 0 ... bytes.length) out += String.fromCharCode(bytes.get(n));
        return out;
    }
}