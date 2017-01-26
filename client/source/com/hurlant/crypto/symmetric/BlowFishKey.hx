/**
 * BlowFishKey
 * 
 * An Actionscript 3 implementation of the BlowFish encryption algorithm,
 * as documented at http://www.schneier.com/blowfish.html
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
import com.hurlant.crypto.symmetric.ISymmetricKey;

import com.hurlant.util.ByteArray;
import com.hurlant.util.Memory;

class BlowFishKey implements ISymmetricKey {

    // ====================================
    // Useful constants
    // ====================================

    private static inline var ROUNDS:Int32 = 16;
    private static inline var BLOCK_SIZE:Int32 = 8; // bytes = 64 bits
    private static inline var SBOX_SK:Int32 = 256;
    private static var P_SZ:Int32 = ROUNDS + 2;

    private var S0:Array<Int32>;
    private var S1:Array<Int32>;
    private var S2:Array<Int32>;
    private var S3:Array<Int32>; // the s-boxes
    private var P:Array<Int32>; // the p-array

    private var key:ByteArray = null;

    public function new(key:ByteArray) {
        this.key = key;
        setKey(key);
    }

    public function getBlockSize():Int32 {
        return BLOCK_SIZE;
    }

    public function decrypt(block:ByteArray, index:Int32 = 0):Void {
        decryptBlock(block, index, block, index);
    }

    public function dispose():Void {
        var i:Int32 = 0;
        ArrayUtil.secureDisposeIntArray(S0);
        ArrayUtil.secureDisposeIntArray(S1);
        ArrayUtil.secureDisposeIntArray(S2);
        ArrayUtil.secureDisposeIntArray(S3);
        ArrayUtil.secureDisposeIntArray(P);
        ArrayUtil.secureDisposeByteArray(key);
        S0 = null;
        S1 = null;
        S2 = null;
        S3 = null;
        P = null;
        key.length = 0;
        key = null;
        Memory.gc();
    }

    public function encrypt(block:ByteArray, index:Int32 = 0):Void {
        encryptBlock(block, index, block, index);
    }

    private function F(x:Int32):Int32 {
        return (((S0[(x >>> 24)] + S1[(x >>> 16) & 0xff]) ^ S2[(x >>> 8) & 0xff]) + S3[x & 0xff]);
    }

    /**
     * apply the encryption cycle to each value pair in the table.
     */

    private function processTable(xl:Int32, xr:Int32, table:Array<Int32>):Void {
        var size = table.length;

        var s = 0;
        while (s < size) {
            xl ^= P[0];

            var i:Int32 = 1;
            while (i < ROUNDS) {
                xr ^= F(xl) ^ P[i + 0];
                xl ^= F(xr) ^ P[i + 1];
                i += 2;
            }

            xr ^= P[ROUNDS + 1];

            table[s] = xr;
            table[s + 1] = xl;

            xr = xl; // end of cycle swap
            xl = table[s];
            s += 2;
        }
    }

    private function setKey(key:ByteArray):Void {
        /*
         * - comments are from _Applied Crypto_, Schneier, p338 please be
         * careful comparing the two, AC numbers the arrays from 1, the enclosed
         * code from 0.
         *
         * (1) Initialise the S-boxes and the P-array, with a fixed string This
         * string contains the hexadecimal digits of pi (3.141...)
         */
        S0 = BlowFishKeyTables.KS0.slice(0);
        S1 = BlowFishKeyTables.KS1.slice(0);
        S2 = BlowFishKeyTables.KS2.slice(0);
        S3 = BlowFishKeyTables.KS3.slice(0);
        P = BlowFishKeyTables.KP.slice(0);

        /*
         * (2) Now, XOR P[0] with the first 32 bits of the key, XOR P[1] with
         * the second 32-bits of the key, and so on for all bits of the key (up
         * to P[17]). Repeatedly cycle through the key bits until the entire
         * P-array has been XOR-ed with the key bits
         */
        var keyLength:Int32 = key.length;
        var keyIndex:Int32 = 0;

        for (i in 0...P_SZ) {
            // get the 32 bits of the key, in 4 * 8 bit chunks
            var data:Int32 = 0x0000000;
            for (j in 0...4) {
                // create a 32 bit block
                data = (data << 8) | (key[keyIndex++] & 0xff);

                // wrap when we get to the end of the key
                if (keyIndex >= keyLength) {
                    keyIndex = 0;
                }
            } // XOR the newly created 32 bit chunk onto the P-array

            P[i] ^= data;
        }

        /*
         * (3) Encrypt the all-zero string with the Blowfish algorithm, using
         * the subkeys described in (1) and (2)
         *
         * (4) Replace P1 and P2 with the output of step (3)
         *
         * (5) Encrypt the output of step(3) using the Blowfish algorithm, with
         * the modified subkeys.
         *
         * (6) Replace P3 and P4 with the output of step (5)
         *
         * (7) Continue the process, replacing all elements of the P-array and
         * then all four S-boxes in order, with the output of the continuously
         * changing Blowfish algorithm
         */

        processTable(0, 0, P);
        processTable(P[P_SZ - 2], P[P_SZ - 1], S0);
        processTable(S0[SBOX_SK - 2], S0[SBOX_SK - 1], S1);
        processTable(S1[SBOX_SK - 2], S1[SBOX_SK - 1], S2);
        processTable(S2[SBOX_SK - 2], S2[SBOX_SK - 1], S3);
    }

    /**
     * Encrypt the given input starting at the given offset and place the result
     * in the provided buffer starting at the given offset. The input will be an
     * exact multiple of our blocksize.
     */

    private function encryptBlock(src:ByteArray, srcIndex:Int32, dst:ByteArray, dstIndex:Int32):Void {
        var xl = BytesTo32bits(src, srcIndex);
        var xr = BytesTo32bits(src, srcIndex + 4);

        xl ^= P[0];

        var i:Int32 = 1;
        while (i < ROUNDS) {
            xr ^= F(xl) ^ P[i + 0];
            xl ^= F(xr) ^ P[i + 1];
            i += 2;
        }

        xr ^= P[ROUNDS + 1];

        Bits32ToBytes(xr, dst, dstIndex);
        Bits32ToBytes(xl, dst, dstIndex + 4);
    }

    /**
     * Decrypt the given input starting at the given offset and place the result
     * in the provided buffer starting at the given offset. The input will be an
     * exact multiple of our blocksize.
     */

    private function decryptBlock(src:ByteArray, srcIndex:Int32, dst:ByteArray, dstIndex:Int32):Void {
        var xl = BytesTo32bits(src, srcIndex);
        var xr = BytesTo32bits(src, srcIndex + 4);

        xl ^= P[ROUNDS + 1];

        var i:Int32 = ROUNDS;
        while (i > 0) {
            xr ^= F(xl) ^ P[i - 0];
            xl ^= F(xr) ^ P[i - 1];
            i -= 2;
        }

        xr ^= P[0];

        Bits32ToBytes(xr, dst, dstIndex);
        Bits32ToBytes(xl, dst, dstIndex + 4);
    }

    private function BytesTo32bits(b:ByteArray, i:Int32):Int32 {
        return ((b[i] & 0xff) << 24) | ((b[i + 1] & 0xff) << 16) | ((b[i + 2] & 0xff) << 8) | ((b[i + 3] & 0xff));
    }

    private function Bits32ToBytes(i:Int32, b:ByteArray, offset:Int32):Void {
        b[offset + 3] = i;
        b[offset + 2] = (i >> 8);
        b[offset + 1] = (i >> 16);
        b[offset] = (i >> 24);
    }

    public function toString():String {
        return "blowfish";
    }
}


