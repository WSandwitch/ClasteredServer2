package com.hurlant.crypto.hash;

import com.hurlant.util.Std2;
import com.hurlant.util.ByteArray;
import haxe.Int32;

class RMD160 implements IHash {
    public static inline var HASH_SIZE = 20;

    public var pad_size:Int32 = 40;

    public function getInputSize():Int32 {
        return 64;
    }

    public function getHashSize():Int32 {
        return HASH_SIZE;
    }

    public function getPadSize():Int32 {
        return pad_size;
    }

    public function new() {
    }

    /**
	* Private properties of the class.
	*/
    private static var r1:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8, 3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12, 1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2, 4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13];
    private static var r2:Array<Int> = [5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12, 6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2, 15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13, 8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14, 12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11];
    private static var s1:Array<Int> = [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8, 7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12, 11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5, 11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12, 9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6];
    private static var s2:Array<Int> = [8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6, 9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11, 9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5, 15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8, 8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11];

    public function hash(src:ByteArray):ByteArray {
        throw 'Not working yet!';
        var oldLength = src.length;
        src.length = Std2.roundUp(src.length, 8);
        var value = core(src.toInt32ArrayBE(), oldLength * 8);
        src.length = oldLength;
        return ByteArray.fromInt32ArrayBE(value);
    }

    private static inline function core(x:Array<Int32>, l:Int32):Array<Int32> {
        x[l >> 5] |= 0x80 << (l % 32);
        x[(((l + 64) >>> 9) << 4) + 14] = l;
        var i:Int = 0;
        var h0:Int = 0x67452301;
        var h1:Int = 0xefcdab89;
        var h2:Int = 0x98badcfe;
        var h3:Int = 0x10325476;
        var h4:Int = 0xc3d2e1f0;
        while (i < x.length) {
            var t:Int, a1:Int = h0, b1:Int = h1, c1:Int = h2;
            var d1:Int = h3, e1:Int = h4, a2:Int = h0, b2:Int = h1;
            var c2:Int = h2, d2:Int = h3, e2:Int = h4;
            for (j in 0...80) {
                t = add(a1, f(j, b1, c1, d1));
                t = add(t, x[i + r1[j]]);
                t = add(t, k1(j));
                t = add(rol(t, s1[j]), e1);
                a1 = e1; e1 = d1;
                d1 = rol(c1, 10);
                c1 = b1; b1 = t;
                t = add(a2, f(79 - j, b2, c2, d2));
                t = add(t, x[i + r2[j]]);
                t = add(t, k2(j));
                t = add(rol(t, s2[j]), e2);
                a2 = e2; e2 = d2;
                d2 = rol(c2, 10);
                c2 = b2; b2 = t;
            }
            t = add(h1, add(c1, d2));
            h1 = add(h2, add(d1, e2));
            h2 = add(h3, add(e1, a2));
            h3 = add(h4, add(a1, b2));
            h4 = add(h0, add(b1, c2));
            h0 = t;
            i += 16;
        }
        return [h0, h1, h2, h3, h4];
    }

    private static inline function f(j:Int, x:Int, y:Int, z:Int):Int {
        return (0 <= j && j <= 15) ? (x ^ y ^ z) : (16 <= j && j <= 31) ? (x & y) | (~x & z) : (32 <= j && j <= 47) ? (x | ~y) ^ z : (48 <= j && j <= 63) ? (x & z) | (y & ~z) : (64 <= j && j <= 79) ? x ^ (y | ~z) : Std.int(Math.NEGATIVE_INFINITY);
    }

    private static inline function k1(j:Int):Int {
        return (0 <= j && j <= 15) ? 0x00000000 : (16 <= j && j <= 31) ? 0x5a827999 : (32 <= j && j <= 47) ? 0x6ed9eba1 : (48 <= j && j <= 63) ? 0x8f1bbcdc : (64 <= j && j <= 79) ? 0xa953fd4e : Std.int(Math.NEGATIVE_INFINITY);
    }

    private static inline function k2(j:Int):Int {
        return (0 <= j && j <= 15) ? 0x50a28be6 : (16 <= j && j <= 31) ? 0x5c4dd124 : (32 <= j && j <= 47) ? 0x6d703ef3 : (48 <= j && j <= 63) ? 0x7a6d76e9 : (64 <= j && j <= 79) ? 0x00000000 : Std.int(Math.NEGATIVE_INFINITY);
    }

    private static inline function add(x:Int, y:Int):Int {
        var l:Int = (x & 0xFFFF) + (y & 0xFFFF);
        var m:Int = (x >> 16) + (y >> 16) + (l >> 16);
        return (m << 16) | (l & 0xFFFF);
    }

    private static inline function rol(n:Int, c:Int):Int {
        return (n << c) | (n >>> (32 - c));
    }

    public function toString():String {
        return "rmd160";
    }
}