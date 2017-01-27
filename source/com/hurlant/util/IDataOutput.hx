package com.hurlant.util;

import haxe.Int32;
interface IDataOutput {
    function writeByte(value:Int32):Void;
    function writeShort(value:Int32):Void;
    //function writeBytes(input:ByteArray, offset:Int32 = 0, length:Int32 = 0);
}