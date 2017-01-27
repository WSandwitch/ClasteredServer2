/**
 * OFBMode
 * 
 * An ActionScript 3 implementation of the OFB confidentiality mode
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric.mode;


import com.hurlant.crypto.symmetric.mode.IMode;
import com.hurlant.crypto.symmetric.mode.IVMode;
import com.hurlant.crypto.pad.IPad;
import haxe.Int32;
import com.hurlant.util.ByteArray;

class OFBMode extends IVMode implements IMode {
    public function new(key:ISymmetricKey, padding:IPad = null) {
        super(key, null);
    }

    public function encrypt(src:ByteArray):Void {
        var vector:ByteArray = getIV4e();
        core(src, vector);
    }

    public function decrypt(src:ByteArray):Void {
        var vector:ByteArray = getIV4d();
        core(src, vector);
    }

    private function core(src:ByteArray, iv:ByteArray):Void {
        var l:Int32 = src.length;
        var tmp:ByteArray = new ByteArray();
        var i:Int32 = 0;
        while (i < src.length) {
            key.encrypt(iv);
            tmp.position = 0;
            tmp.writeBytes(iv);
            var chunk:Int32 = ((i + blockSize < l)) ? blockSize : l - i;
            for (j in 0...chunk) {
                src[i + j] ^= iv[j];
            }
            iv.position = 0;
            iv.writeBytes(tmp);
            i += blockSize;
        }
    }

    public function toString():String {
        return key.toString() + "-ofb";
    }
}
