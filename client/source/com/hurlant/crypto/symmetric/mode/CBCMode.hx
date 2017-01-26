/**
 * CBCMode
 * 
 * An ActionScript 3 implementation of the CBC confidentiality mode
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric.mode;

import haxe.Int32;
import com.hurlant.crypto.pad.IPad;
import com.hurlant.crypto.symmetric.ISymmetricKey;

import com.hurlant.util.ByteArray;

/**
 * CBC confidentiality mode. why not.
 */
class CBCMode extends IVMode implements IMode {
    public function new(key:ISymmetricKey, padding:IPad = null) {
        super(key, padding);
    }

    public function encrypt(src:ByteArray):Void {
        padding.pad(src);
        var vector:ByteArray = getIV4e();
        var i:Int32 = 0;
        while (i < src.length) {
            for (j in 0...blockSize) {
                src[i + j] ^= vector[j];
            }
            key.encrypt(src, i);
            vector.position = 0;
            vector.writeBytes(src, i, blockSize);
            i += blockSize;
        }
    }

    public function decrypt(src:ByteArray):Void {
        var vector:ByteArray = getIV4d();
        var tmp:ByteArray = new ByteArray();
        var i:Int32 = 0;
        while (i < src.length) {
            tmp.position = 0;
            tmp.writeBytes(src, i, blockSize);
            key.decrypt(src, i);
            for (j in 0...blockSize) {
                src[i + j] ^= vector[j];
            }
            vector.position = 0;
            vector.writeBytes(tmp, 0, blockSize);
            i += blockSize;
        }
        padding.unpad(src);
    }

    public function toString():String {
        return key.toString() + "-cbc";
    }
}
