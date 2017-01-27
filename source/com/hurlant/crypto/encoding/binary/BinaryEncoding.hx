package com.hurlant.crypto.encoding.binary;

import haxe.io.Bytes;

interface BinaryEncoding {
    function encode(input:Bytes):String;
    function decode(input:String):Bytes;
}