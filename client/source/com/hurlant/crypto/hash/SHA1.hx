/**
 * SHA1
 * 
 * An ActionScript 3 implementation of Secure Hash Algorithm, SHA-1, as defined
 * in FIPS PUB 180-1
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		A JavaScript implementation of the Secure Hash Algorithm, SHA-1, as defined
 * 		in FIPS PUB 180-1
 * 		Version 2.1a Copyright Paul Johnston 2000 - 2002.
 * 		Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.hash;

import haxe.Int32;
import com.hurlant.util.Std2;
import com.hurlant.crypto.hash.SHABase;


class SHA1 extends SHABase implements IHash {
    public static inline var HASH_SIZE = 20;

    override public function getHashSize():Int32 {
        return HASH_SIZE;
    }

    override private function core(x:Array<Int32>, len:Int32):Array<Int32> {
	#if neko
		if (x[len >> 5] == null)
			x[len >> 5] = 0;
    #end
		x[len >> 5] |= 0x80 << (24 - len % 32);
        x[((len + 64 >> 9) << 4) + 15] = len;

        for (n in 0 ... x.length){
		#if neko
			if (x[n] == null)
				x[n] = 0;
		#end
			x[n] |= 0;
		}

        var w:Array<Int32> = [];
        var a:Int32 = 0x67452301; //1732584193;
        var b:Int32 = 0xEFCDAB89; //-271733879;
        var c:Int32 = 0x98BADCFE; //-1732584194;
        var d:Int32 = 0x10325476; //271733878;
        var e:Int32 = 0xC3D2E1F0; //-1009589776;

        var i:Int32 = 0;
        while (i < x.length) {
            var olda:Int32 = a;
            var oldb:Int32 = b;
            var oldc:Int32 = c;
            var oldd:Int32 = d;
            var olde:Int32 = e;

            for (j in 0...80) {
                if (j < 16) {
                    w[j] = x[i + j];
                } else {
                    w[j] = rol(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
                }
                var t = rol(a, 5) + ft(j, b, c, d) + e + w[j] + kt(j);
                e = d;
                d = c;
                c = rol(b, 30);
                b = a;
                a = t;
            }
            a += olda;
            b += oldb;
            c += oldc;
            d += oldd;
            e += olde;
            i += 16;
        }
        return [a, b, c, d, e];
    }

    private function rol(num:Int32, cnt:Int32):Int32 {
        return Std2.rol(num, cnt);
    }

    /*
     * Perform the appropriate triplet combination function for the current
     * iteration
     */

    private function ft(t:Int32, b:Int32, c:Int32, d:Int32):Int32 {
        if (t < 20) return (b & c) | ((~b) & d);
        if (t < 40) return b ^ c ^ d;
        if (t < 60) return (b & c) | (b & d) | (c & d);
        return b ^ c ^ d;
    }

    /*
     * Determine the appropriate additive constant for the current iteration
     */

    private function kt(t:Int32):Int32 {
        return ((t < 20)) ? 0x5A827999 : ((t < 40)) ? 0x6ED9EBA1 : ((t < 60)) ? 0x8F1BBCDC : 0xCA62C1D6;
    }

    override public function toString():String {
        return "sha1";
    }

    public function new() {
        super();
    }
}
