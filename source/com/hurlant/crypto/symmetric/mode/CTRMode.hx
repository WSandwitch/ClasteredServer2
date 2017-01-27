/**
 * CTRMode
 * 
 * An ActionScript 3 implementation of the counter confidentiality mode
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric.mode;

import haxe.Int32;
import com.hurlant.crypto.pad.IPad;
import com.hurlant.crypto.symmetric.ISymmetricKey;

import com.hurlant.util.ByteArray;

class CTRMode extends IVMode implements IMode {
    public function new(key:ISymmetricKey, padding:IPad = null) {
        super(key, padding);
    }

    public function encrypt(src:ByteArray):Void {
        padding.pad(src);
        var vector:ByteArray = getIV4e();
        core(src, vector);
    }

    public function decrypt(src:ByteArray):Void {
        var vector:ByteArray = getIV4d();
        core(src, vector);
        padding.unpad(src);
    }

    private function core(src:ByteArray, iv:ByteArray):Void {
        var X:ByteArray = new ByteArray();
        var Xenc:ByteArray = new ByteArray();
        X.writeBytes(iv);
        var i:Int32 = 0;
        while (i < src.length) {
            Xenc.position = 0;
            Xenc.writeBytes(X);
            key.encrypt(Xenc);
            for (j in 0...blockSize) {
                src[i + j] ^= Xenc[j];
            }

            var j = blockSize - 1;
            while (j >= 0) {
                X[j] = X[j] + 1;
                if (X[j] != 0)break;
                j--;
            }
            i += blockSize;
        }
    }

    public function toString():String {
        return key.toString() + "-ctr";
    }
}
