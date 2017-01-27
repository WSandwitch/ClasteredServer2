/**
 * CFB8Mode
 * 
 * An ActionScript 3 implementation of the CFB-8 confidentiality mode
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
 *
 * Note: The constructor accepts an optional padding argument, but ignores it otherwise.
 */
class CFB8Mode extends IVMode implements IMode {
    public function new(key:ISymmetricKey, padding:IPad = null) {
        super(key, null);
    }

    public function encrypt(src:ByteArray):Void {
        var vector:ByteArray = getIV4e();
        var tmp:ByteArray = new ByteArray();
        for (i in 0...src.length) {
            tmp.position = 0;
            tmp.writeBytes(vector);
            key.encrypt(vector);
            src[i] ^= vector[0];
            // rotate
            for (j in 0...blockSize - 1) {
                vector[j] = tmp[j + 1];
            }
            vector[blockSize - 1] = src[i];
        }
    }

    public function decrypt(src:ByteArray):Void {
        var vector = getIV4d();
        var tmp = new ByteArray();
        for (i in 0...src.length) {
            var c:Int32 = src[i];
            tmp.position = 0;
            tmp.writeBytes(vector); // I <- tmp
            key.encrypt(vector); // O <- vector
            src[i] ^= vector[0];
            // rotate
            for (j in 0...blockSize - 1) {
                vector[j] = tmp[j + 1];
            }
            vector[blockSize - 1] = c;
        }
    }

    public function toString():String {
        return key.toString() + "-cfb8";
    }
}
