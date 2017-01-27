package com.hurlant.crypto.extra;

import haxe.io.Bytes;
class ROT13 {
    // Symmetric
    static public function encode(input:Bytes):Bytes {
        return ROT.rotateBytes(input, 13);
    }

    static public function decode(input:Bytes):Bytes {
        return ROT.rotateBytes(input, 13);
    }

    static public function encodeString(input:String):String {
        return ROT.rotateString(input, 13);
    }

    static public function decodeString(input:String):String {
        return ROT.rotateString(input, 13);
    }
}