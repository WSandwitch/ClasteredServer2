/**
 * SHABase
 * 
 * An ActionScript 3 abstract class for the SHA family of hash functions
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.hash;


import haxe.Int32;
import com.hurlant.util.ByteArray;
import com.hurlant.util.Endian;

class SHABase implements IHash {
    public var pad_size:Int32 = 40;

    public function getInputSize():Int32 {
        return 64;
    }

    public function getHashSize():Int32 {
        return 0;
    }

    public function getPadSize():Int32 {
        return pad_size;
    }

    public function hash(src:ByteArray):ByteArray {
        var savedLength = src.length;
        var savedEndian = src.endian;

        src.endian = Endian.BIG_ENDIAN;
        var len:Int32 = savedLength * 8;
        // pad to nearest int.
        while ((src.length % 4) != 0) src[src.length] = 0;

        src.position = 0;
        var a:Array<Int32> = [];
        var i:Int32 = 0;
        while (i < src.length) {
            a.push(src.readUnsignedInt());
            i += 4;
        }
        var h = core(a, len);
        //trace(h);
        //trace(Std2.toStringHex(h[0]));
        //trace(Std2.toStringHex(h[1]));
        //trace(Std2.toStringHex(h[2]));
        //trace(Std2.toStringHex(h[3]));
        var out = new ByteArray();
        var words = Std.int(getHashSize() / 4);
        for (i in 0...words) {
            //trace(h[i] + ":" + Std2.toStringHex(h[i]));
            out.writeUnsignedInt(h[i]); // unpad, to leave the source untouched.
        }
        //trace(out);

        src.length = savedLength;
        src.endian = savedEndian;
        return out;
    }

    private function core(x:Array<Int32>, len:Int32):Array<Int32> {
        return null;
    }

    public function toString():String {
        return "sha";
    }

    public function new() {
    }
}
