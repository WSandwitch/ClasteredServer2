package com.hurlant.crypto.prng;

import haxe.Int32;
import com.hurlant.util.ByteArray;
interface IRandom {
    function getRandomBytes(length:Int32):ByteArray;
}