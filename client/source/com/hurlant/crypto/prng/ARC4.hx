/**
 * ARC4
 * 
 * An ActionScript 3 implementation of RC4
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The jsbn library, Copyright (c) 2003-2005 Tom Wu
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.prng;

import haxe.Int32;
import com.hurlant.crypto.prng.IPRNG;

import com.hurlant.crypto.symmetric.IStreamCipher;
import com.hurlant.util.Memory;

import com.hurlant.util.ByteArray;

class ARC4 implements IPRNG implements IStreamCipher {
    private var i:Int32 = 0;
    private var j:Int32 = 0;
    private var S:ByteArray;
    static private inline var psize:Int32 = 256;

    public function new(key:ByteArray = null) {
        S = new ByteArray();
        if (key != null) {
            init(key);
        }
    }

    public function getPoolSize():Int32 {
        return psize;
    }

    public function init(key:ByteArray):Void {
        for (i in 0...256) S[i] = i;
        var j = 0;
        for (i in 0...256) {
            j = (j + S[i] + key[i % key.length]) & 255;
            var t = S[i];
            S[i] = S[j];
            S[j] = t;
        }
        this.i = 0;
        this.j = 0;
    }

    public function next():Int32 {
        i = (i + 1) & 255;
        j = (j + S[i]) & 255;
        var t = S[i];
        S[i] = S[j];
        S[j] = t;
        return S[(t + S[i]) & 255];
    }

    public function getBlockSize():Int32 {
        return 1;
    }

    public function encrypt(block:ByteArray):Void {
        var i:Int32 = 0;
        while (i < block.length) block[i++] ^= next();
    }

    public function decrypt(block:ByteArray):Void {
        encrypt(block);
    }

    public function dispose():Void {
        var i:Int32 = 0;
        if (S != null) {
            for (i in 0...S.length) S[i] = Std.random(256);
            S.length = 0;
            S = null;
        }
        this.i = 0;
        this.j = 0;
        Memory.gc();
    }

    public function toString():String {
        return "rc4";
    }
}
