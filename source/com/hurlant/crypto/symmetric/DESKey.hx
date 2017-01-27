/**
 * DESKey
 * 
 * An Actionscript 3 implementation of the Data Encryption Standard (DES)
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
import com.hurlant.crypto.symmetric.DESKeyTables;
import com.hurlant.util.ArrayUtil;
import com.hurlant.crypto.symmetric.ISymmetricKey;

import com.hurlant.util.ByteArray;
import com.hurlant.util.Memory;

class DESKey implements ISymmetricKey {
    private var key:ByteArray;
    private var encKey:Array<Int32>;
    private var decKey:Array<Int32>;


    public function new(key:ByteArray) {
        this.key = key;
        this.encKey = generateWorkingKey(true, key, 0);
        this.decKey = generateWorkingKey(false, key, 0);
    }

    public function getBlockSize():Int32 {
        return 8;
    }

    public function decrypt(block:ByteArray, index:Int32 = 0):Void {
        desFunc(decKey, block, index, block, index);
    }

    public function dispose():Void {
        ArrayUtil.secureDisposeIntArray(encKey);
        ArrayUtil.secureDisposeIntArray(decKey);
        ArrayUtil.secureDisposeByteArray(key);
        encKey = null;
        decKey = null;
        key.length = 0;
        key = null;
        Memory.gc();
    }

    public function encrypt(block:ByteArray, index:Int32 = 0):Void {
        desFunc(encKey, block, index, block, index);
    }


    /**
     * generate an integer based working key based on our secret key and what we
     * processing we are planning to do.
     *
     * Acknowledgements for this routine go to James Gillogly & Phil Karn.
     */

    private function generateWorkingKey(encrypting:Bool, key:ByteArray, off:Int32):Array<Int32> {
        //int[] newKey = new int[32];
        var newKey:Array<Int32> = [];
        //boolean[] pc1m = new boolean[56], pcr = new boolean[56];
        var pc1m:ByteArray = new ByteArray();
        var pcr:ByteArray = new ByteArray();

        var l:Int32;

        for (j in 0...56) {
            l = DESKeyTables.pc1[j];
            pc1m[j] = ((key.get(off + (l >>> 3)) & DESKeyTables.bytebit[l & 7]) != 0) ? 1 : 0;
        }

        for (i in 0...16) {
            var m = encrypting ? (i << 1) : ((15 - i) << 1);
            var n = m + 1;

            newKey[m] = newKey[n] = 0;

            for (j in 0...28) {
                l = j + DESKeyTables.totrot[i];
                pcr[j] = (l < 28) ? pc1m[l] : pc1m[l - 28];
            }

            for (j in 28...56) {
                l = j + DESKeyTables.totrot[i];
                pcr[j] = (l < 56) ? pc1m[l] : pc1m[l - 28];
            }

            for (j in 0 ... 24) {
                if (pcr[DESKeyTables.pc2[j + 0]] != 0) newKey[m] |= DESKeyTables.bigbyte[j];
                if (pcr[DESKeyTables.pc2[j + 24]] != 0) newKey[n] |= DESKeyTables.bigbyte[j];
            }
        }

        var i = 0;
        while (i != 32) {
            var i1 = newKey[i + 0];
            var i2 = newKey[i + 1];
            newKey[i + 0] = ((i1 & 0x00fc0000) <<  6) | ((i1 & 0x00000fc0) << 10) | ((i2 & 0x00fc0000) >>> 10) | ((i2 & 0x00000fc0) >>> 6);
            newKey[i + 1] = ((i1 & 0x0003f000) << 12) | ((i1 & 0x0000003f) << 16) | ((i2 & 0x0003f000) >>>  4) | ((i2 & 0x0000003f) >>> 0);
            i += 2;
        }

        return newKey;
    }

    /**
     * the DES engine.
     */

    private function desFunc(wKey:Array<Int32>, inp:ByteArray, inOff:Int32, out:ByteArray, outOff:Int32):Void {
        var work:Int32;
        var right:Int32 = 0;
        var left:Int32 = 0;

        left |= (inp[inOff + 0] & 0xff) << 24;
        left |= (inp[inOff + 1] & 0xff) << 16;
        left |= (inp[inOff + 2] & 0xff) << 8;
        left |= (inp[inOff + 3] & 0xff) << 0;

        right |= (inp[inOff + 4] & 0xff) << 24;
        right |= (inp[inOff + 5] & 0xff) << 16;
        right |= (inp[inOff + 6] & 0xff) << 8;
        right |= (inp[inOff + 7] & 0xff) << 0;

        work = ((left >>> 4) ^ right) & 0x0f0f0f0f;
        right ^= work;
        left  ^= (work << 4);

        work = ((left >>> 16) ^ right) & 0x0000ffff;
        right ^= work;
        left  ^= (work << 16);

        work = ((right >>> 2) ^ left) & 0x33333333;
        left  ^= work;
        right ^= (work << 2);

        work = ((right >>> 8) ^ left) & 0x00ff00ff;
        left ^= work;
        right ^= (work << 8);
        right = ((right << 1) | ((right >>> 31) & 1)) & 0xffffffff;

        work = (left ^ right) & 0xaaaaaaaa;
        left ^= work;
        right ^= work;
        left = ((left << 1) | ((left >>> 31) & 1)) & 0xffffffff;


        for (round in 0...8) {
            var fval:Int32;

            work = (right << 28) | (right >>> 4);
            work ^= wKey[round * 4 + 0];
            fval = DESKeyTables.SP7[work & 0x3f];
            fval |= DESKeyTables.SP5[(work >>> 8) & 0x3f];
            fval |= DESKeyTables.SP3[(work >>> 16) & 0x3f];
            fval |= DESKeyTables.SP1[(work >>> 24) & 0x3f];
            work = right ^ wKey[round * 4 + 1];
            fval |= DESKeyTables.SP8[work & 0x3f];
            fval |= DESKeyTables.SP6[(work >>> 8) & 0x3f];
            fval |= DESKeyTables.SP4[(work >>> 16) & 0x3f];
            fval |= DESKeyTables.SP2[(work >>> 24) & 0x3f];
            left ^= fval;
            work = (left << 28) | (left >>> 4);
            work ^= wKey[round * 4 + 2];
            fval  = DESKeyTables.SP7[work & 0x3f];
            fval |= DESKeyTables.SP5[(work >>> 8) & 0x3f];
            fval |= DESKeyTables.SP3[(work >>> 16) & 0x3f];
            fval |= DESKeyTables.SP1[(work >>> 24) & 0x3f];
            work = left ^ wKey[round * 4 + 3];
            fval |= DESKeyTables.SP8[work & 0x3f];
            fval |= DESKeyTables.SP6[(work >>> 8) & 0x3f];
            fval |= DESKeyTables.SP4[(work >>> 16) & 0x3f];
            fval |= DESKeyTables.SP2[(work >>> 24) & 0x3f];
            right ^= fval;
        }

        right = (right << 31) | (right >>> 1);
        work = (left ^ right) & 0xaaaaaaaa;
        left ^= work;
        right ^= work;
        left = (left << 31) | (left >>> 1);
        work = ((left >>> 8) ^ right) & 0x00ff00ff;
        right ^= work;
        left ^= (work << 8);
        work = ((left >>> 2) ^ right) & 0x33333333;
        right ^= work;
        left ^= (work << 2);
        work = ((right >>> 16) ^ left) & 0x0000ffff;
        left ^= work;
        right ^= (work << 16);
        work = ((right >>> 4) ^ left) & 0x0f0f0f0f;
        left ^= work;
        right ^= (work << 4);

        out[outOff + 0] = ((right >>> 24) & 0xff);
        out[outOff + 1] = ((right >>> 16) & 0xff);
        out[outOff + 2] = ((right >>> 8) & 0xff);
        out[outOff + 3] = (right & 0xff);
        out[outOff + 4] = ((left >>> 24) & 0xff);
        out[outOff + 5] = ((left >>> 16) & 0xff);
        out[outOff + 6] = ((left >>> 8) & 0xff);
        out[outOff + 7] = (left & 0xff);
    }


    public function toString():String {
        return "des";
    }
}
