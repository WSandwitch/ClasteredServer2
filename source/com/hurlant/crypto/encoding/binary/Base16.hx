package com.hurlant.crypto.encoding.binary;

import haxe.io.Bytes;
class Base16 implements BinaryEncoding {
    public function new() {
    }

    public function encode(input:Bytes):String {
        return com.hurlant.util.Hex.fromArray(input);
    }

    public function decode(input:String):Bytes {
        return com.hurlant.util.Hex.toArray(input);
    }
}