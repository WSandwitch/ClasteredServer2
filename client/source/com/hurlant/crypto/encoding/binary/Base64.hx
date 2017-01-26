package com.hurlant.crypto.encoding.binary;

import haxe.io.Bytes;
class Base64 implements BinaryEncoding {
    public function new() {
    }

    public function encode(input:Bytes):String {
        return com.hurlant.util.Base64.encodeByteArray(input);
    }

    public function decode(input:String):Bytes {
        return com.hurlant.util.Base64.decodeToByteArray(input);
    }
}