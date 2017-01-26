/**
 * XTeaKey
 * 
 * An ActionScript 3 implementation of the XTea algorithm
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric;


import haxe.Int32;
import com.hurlant.util.ArrayUtil;
import com.hurlant.util.Std2;
import com.hurlant.util.Memory;

import com.hurlant.util.ByteArray;

class XTeaKey implements ISymmetricKey {
    static private inline var NUM_ROUNDS = 64;
    static private inline var delta = 0x9E3779B9;
    private var k:Array<Int32>;

    public function new(a:ByteArray) {
        a.position = 0;
        k = [a.readUnsignedInt(), a.readUnsignedInt(), a.readUnsignedInt(), a.readUnsignedInt()];
    }

    /**
     * K is an hex string with 32 digits.
     */
    public static function parseKey(K:String):XTeaKey {
        var a = new ByteArray();
        a.writeUnsignedInt(Std2.parseInt(K.substr(0, 8), 16));
        a.writeUnsignedInt(Std2.parseInt(K.substr(8, 8), 16));
        a.writeUnsignedInt(Std2.parseInt(K.substr(16, 8), 16));
        a.writeUnsignedInt(Std2.parseInt(K.substr(24, 8), 16));
        a.position = 0;
        return new XTeaKey(a);
    }

    public function getBlockSize():Int32 {
        return 8;
    }

    public function encrypt(block:ByteArray, index:Int32 = 0):Void {
        block.position = index;
        var v0:Int32 = block.readUnsignedInt();
        var v1:Int32 = block.readUnsignedInt();
        var sum:Int32 = 0;

        for (i in 0...NUM_ROUNDS) {
            v0 += (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + k[(sum >> 0) & 3]);
            sum += delta;
            v1 += (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + k[(sum >> 11) & 3]);
        }
        block.position -= 8;
        block.writeUnsignedInt(v0);
        block.writeUnsignedInt(v1);
    }

    public function decrypt(block:ByteArray, index:Int32 = 0):Void {
        block.position = index;
        var v0:Int32 = block.readUnsignedInt();
        var v1:Int32 = block.readUnsignedInt();
        var sum:Int32 = delta * NUM_ROUNDS;
        for (i in 0...NUM_ROUNDS) {
            v1 -= (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + k[(sum >> 11) & 3]);
            sum -= delta;
            v0 -= (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + k[(sum >> 0) & 3]);
        }
        block.position -= 8;
        block.writeUnsignedInt(v0);
        block.writeUnsignedInt(v1);
    }

    public function dispose():Void {
        //private var k:Array;
        ArrayUtil.secureDisposeIntArray(k);
        k = null;
        Memory.gc();
    }

    public function toString():String {
        return "xtea";
    }
}


