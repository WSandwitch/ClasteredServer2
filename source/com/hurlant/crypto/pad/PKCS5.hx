/**
 * PKCS5
 * 
 * A padding implementation of PKCS5.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.pad;

import com.hurlant.crypto.pad.IPad;
import com.hurlant.util.ArrayUtil;
import com.hurlant.util.Endian;
import com.hurlant.crypto.hash.SHA1;
import com.hurlant.crypto.hash.HMAC;
import haxe.Int32;
import com.hurlant.util.Error;

import com.hurlant.util.ByteArray;

class PKCS5 implements IPad {
    private var blockSize:Int32;

    public function new(blockSize:Int32 = 0) {
        this.blockSize = blockSize;
    }

    public function pad(a:ByteArray):Void {
        var c:Int32 = blockSize - a.length % blockSize;
        for (i in 0...c) a[a.length] = c;
    }

    public function unpad(a:ByteArray):Void {
        var c:Int32 = a.length % blockSize;
        if (c != 0) throw new Error("PKCS#5::unpad: ByteArray.length isn't a multiple of the blockSize");
        c = a[a.length - 1];
        var i:Int32 = c;
        while (i > 0) {
            var v:Int32 = a[a.length - 1];
            a.length = a.length - 1;
            if (c != v) throw new Error("PKCS#5:unpad: Invalid padding value. expected [" + c + "], found [" + v + "]");
            i--;
        } // that is all.
    }

    public function setBlockSize(bs:Int32):Void {
        blockSize = bs;
    }

    /**
     * Implementation of the PDKDF2 (public based key derivation
     * function 2) from PKCS#5 (rfc2898) chapter 5.2.
     * In this implementation the HMAC-SHA1 will be used as the
     * PRF (pseudorandom function) with a hLen of 20 Bytes.
     *
     * @param p password
     * @param s salt
     * @param c iteration count
     */

    public static function pbkdf2(p:ByteArray, s:ByteArray, c:Int32, dkLen:Int32):ByteArray {
        // TODO make the prf interchangeable
        var prf = new HMAC(new SHA1());
//		var prf : HMAC = new HMAC(new SHA256());
        var hLen = 20;
        var l = Math.ceil(dkLen / hLen);

        // derived key
        var dk:ByteArray = new ByteArray();

        for (i in 1 ... l + 1) {
            var u:ByteArray = new ByteArray();
            u.endian = Endian.BIG_ENDIAN;
            u.writeBytes(s);
            u.writeUnsignedInt(i);

            var f = new ByteArray();
            //prefill f with zeros so xor will work in the inner loop
            for (temp in 0 ... 20) f[temp] = 0;

            for (cLoop in 1 ... c + 1) {
                u = prf.compute(p, u);
                f = ArrayUtil.xorByteArray(f, 0, u, 0, hLen);
            }

            // copy bytes
            var tempLen = dkLen - dk.length;
            if (tempLen > f.length) {
                tempLen = f.length;
            }
            dk.writeBytes(f, 0, tempLen);
        }

        return dk;
    }


}
