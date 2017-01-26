/**
 * TripleDESKey
 * 
 * An Actionscript 3 implementation of Triple DES
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The Bouncy Castle Crypto package, 
 * 		Copyright (c) 2000-2004 The Legion Of The Bouncy Castle
 * 		(http://www.bouncycastle.org)
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric;


import haxe.Int32;
import com.hurlant.util.ArrayUtil;
import com.hurlant.util.ByteArray;
import com.hurlant.util.Memory;

class TripleDESKey extends DESKey {
    private var encKey2:Array<Int32>;
    private var encKey3:Array<Int32>;
    private var decKey2:Array<Int32>;
    private var decKey3:Array<Int32>;

    /**
     * This supports 2TDES and 3TDES.
     * If the key passed is 128 bits, 2TDES is used.
     * If the key has 192 bits, 3TDES is used.
     * Other key lengths give "undefined" results.
     */
    public function new(key:ByteArray) {
        super(key);
        encKey2 = generateWorkingKey(false, key, 8);
        decKey2 = generateWorkingKey(true, key, 8);
        if (key.length > 16) {
            encKey3 = generateWorkingKey(true, key, 16);
            decKey3 = generateWorkingKey(false, key, 16);
        }
        else {
            encKey3 = encKey;
            decKey3 = decKey;
        }
    }

    override public function dispose():Void {
        super.dispose();
        ArrayUtil.secureDisposeIntArray(encKey2);
        ArrayUtil.secureDisposeIntArray(encKey3);
        ArrayUtil.secureDisposeIntArray(decKey2);
        ArrayUtil.secureDisposeIntArray(decKey3);
        encKey2 = encKey3 = null;
        decKey2 = decKey3 = null;
        Memory.gc();
    }

    override public function encrypt(block:ByteArray, index:Int32 = 0):Void {
        desFunc(encKey, block, index, block, index);
        desFunc(encKey2, block, index, block, index);
        desFunc(encKey3, block, index, block, index);
    }

    override public function decrypt(block:ByteArray, index:Int32 = 0):Void {
        desFunc(decKey3, block, index, block, index);
        desFunc(decKey2, block, index, block, index);
        desFunc(decKey, block, index, block, index);
    }

    override public function toString():String {
        return "3des";
    }
}
