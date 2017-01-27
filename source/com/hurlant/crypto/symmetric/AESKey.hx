/**
 * AESKey
 * 
 * An ActionScript 3 implementation of the Advanced Encryption Standard, as
 * defined in FIPS PUB 197
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		A public domain implementation from Karl Malbrain, malbrain@yahoo.com
 * 		(http://www.geocities.com/malbrain/aestable_c.html)
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric;

import haxe.Int32;
import com.hurlant.crypto.symmetric.ISymmetricKey;

import com.hurlant.crypto.prng.Random;
import com.hurlant.util.Memory;

import com.hurlant.util.ByteArray;

class AESKey implements ISymmetricKey {
    // AES only supports Nb=4
    private static inline var Nb = 4; // number of columns in the state & expanded key

    // TODO:
    //  - move those tables in binary files, then
    //  - [Embed()] them as ByteArray directly.
    // (should result in smaller .swf, and faster initialization time.)

    private static var Sbox:ByteArray;
    private static var InvSbox:ByteArray;
    private static var Xtime2Sbox:ByteArray;
    private static var Xtime3Sbox:ByteArray;
    private static var Xtime2:ByteArray;
    private static var Xtime9:ByteArray;
    private static var XtimeB:ByteArray;
    private static var XtimeD:ByteArray;
    private static var XtimeE:ByteArray;
    private static var Rcon:ByteArray;

    // static initializer
    private var key:ByteArray;
    private var keyLength:Int32;
    private var Nr:Int32;
    private var state:ByteArray;
    private var tmp:ByteArray;

    public function new(key:ByteArray) {
        initOnce();
        tmp = new ByteArray();
        state = new ByteArray();
        keyLength = key.length;
        this.key = new ByteArray();
        this.key.writeBytes(key);
        expandKey();
    }

    // produce Nb bytes for each round

    private function expandKey():Void {
        var Nk = Std.int(key.length / 4);
        Nr = Nk + 6;

        for (idx in Nk...Nb * (Nr + 1)) {
            var tmp0 = key[4 * idx - 4];
            var tmp1 = key[4 * idx - 3];
            var tmp2 = key[4 * idx - 2];
            var tmp3 = key[4 * idx - 1];
            if ((idx % Nk) == 0) {
                var tmp4 = tmp3;
                tmp3 = Sbox[tmp0];
                tmp0 = Sbox[tmp1] ^ Rcon[Std.int(idx / Nk)];
                tmp1 = Sbox[tmp2];
                tmp2 = Sbox[tmp4];
            }
            else if (Nk > 6 && idx % Nk == 4) {
                tmp0 = Sbox[tmp0];
                tmp1 = Sbox[tmp1];
                tmp2 = Sbox[tmp2];
                tmp3 = Sbox[tmp3];
            }

            key[4 * idx + 0] = key[4 * idx - 4 * Nk + 0] ^ tmp0;
            key[4 * idx + 1] = key[4 * idx - 4 * Nk + 1] ^ tmp1;
            key[4 * idx + 2] = key[4 * idx - 4 * Nk + 2] ^ tmp2;
            key[4 * idx + 3] = key[4 * idx - 4 * Nk + 3] ^ tmp3;
        }
    }


    public function getBlockSize():Int32 {
        return 16;
    }

    // encrypt one 128 bit block

    public function encrypt(block:ByteArray, index:Int32 = 0):Void {
        var round:Int32;
        state.position = 0;
        state.writeBytes(block, index, Nb * 4);

        addRoundKey(key, 0);
        for (round in 1...Nr + 1) {
            if (round < Nr) {
                mixSubColumns();
            }
            else {
                shiftRows();
            }
            addRoundKey(key, round * Nb * 4);
        }

        block.position = index;
        block.writeBytes(state);
    }

    public function decrypt(block:ByteArray, index:Int32 = 0):Void {
        var round:Int32;
        state.position = 0;
        state.writeBytes(block, index, Nb * 4);

        addRoundKey(key, Nr * Nb * 4);
        invShiftRows();
        round = Nr;
        while (round-- > 0) {
            addRoundKey(key, round * Nb * 4);
            if (round != 0) {
                invMixSubColumns();
            }
        }

        block.position = index;
        block.writeBytes(state);
    }

    public function dispose():Void {
        var i:Int32;
        var r:Random = new Random();
        for (i in 0...key.length) {
            key[i] = r.nextByte();
        }
        Nr = r.nextByte();
        for (i in 0...state.length) {
            state[i] = r.nextByte();
        }
        for (i in 0...tmp.length) {
            tmp[i] = r.nextByte();
        }
        key.length = 0;
        keyLength = 0;
        state.length = 0;
        tmp.length = 0;
        key = null;
        state = null;
        tmp = null;
        Nr = 0;
        Memory.gc();
    }

    // exchanges columns in each of 4 rows
    // row0 - unchanged, row1- shifted left 1,
    // row2 - shifted left 2 and row3 - shifted left 3

    private function shiftRows():Void {
        var tmp:Int32;

        // just substitute row 0
        state[0] = Sbox[state[0]]; state[4] = Sbox[state[4]];
        state[8] = Sbox[state[8]]; state[12] = Sbox[state[12]];

        // rotate row 1
        tmp = Sbox[state[1]]; state[1] = Sbox[state[5]];
        state[5] = Sbox[state[9]]; state[9] = Sbox[state[13]]; state[13] = tmp;

        // rotate row 2
        tmp = Sbox[state[2]]; state[2] = Sbox[state[10]]; state[10] = tmp;
        tmp = Sbox[state[6]]; state[6] = Sbox[state[14]]; state[14] = tmp;

        // rotate row 3
        tmp = Sbox[state[15]]; state[15] = Sbox[state[11]];
        state[11] = Sbox[state[7]]; state[7] = Sbox[state[3]]; state[3] = tmp;
    }

    // restores columns in each of 4 rows
    // row0 - unchanged, row1- shifted right 1,
    // row2 - shifted right 2 and row3 - shifted right 3

    private function invShiftRows():Void {
        var tmp:Int32;

        // restore row 0
        state[0] = InvSbox[state[0]]; state[4] = InvSbox[state[4]];
        state[8] = InvSbox[state[8]]; state[12] = InvSbox[state[12]];

        // restore row 1
        tmp = InvSbox[state[13]]; state[13] = InvSbox[state[9]];
        state[9] = InvSbox[state[5]]; state[5] = InvSbox[state[1]]; state[1] = tmp;

        // restore row 2
        tmp = InvSbox[state[2]]; state[2] = InvSbox[state[10]]; state[10] = tmp;
        tmp = InvSbox[state[6]]; state[6] = InvSbox[state[14]]; state[14] = tmp;

        // restore row 3
        tmp = InvSbox[state[3]]; state[3] = InvSbox[state[7]];
        state[7] = InvSbox[state[11]]; state[11] = InvSbox[state[15]]; state[15] = tmp;
    }

    // recombine and mix each row in a column

    private function mixSubColumns():Void {
        tmp.length = 0;

        // mixing column 0
        tmp[0] = Xtime2Sbox[state[0]] ^ Xtime3Sbox[state[5]] ^ Sbox[state[10]] ^ Sbox[state[15]];
        tmp[1] = Sbox[state[0]] ^ Xtime2Sbox[state[5]] ^ Xtime3Sbox[state[10]] ^ Sbox[state[15]];
        tmp[2] = Sbox[state[0]] ^ Sbox[state[5]] ^ Xtime2Sbox[state[10]] ^ Xtime3Sbox[state[15]];
        tmp[3] = Xtime3Sbox[state[0]] ^ Sbox[state[5]] ^ Sbox[state[10]] ^ Xtime2Sbox[state[15]];

        // mixing column 1
        tmp[4] = Xtime2Sbox[state[4]] ^ Xtime3Sbox[state[9]] ^ Sbox[state[14]] ^ Sbox[state[3]];
        tmp[5] = Sbox[state[4]] ^ Xtime2Sbox[state[9]] ^ Xtime3Sbox[state[14]] ^ Sbox[state[3]];
        tmp[6] = Sbox[state[4]] ^ Sbox[state[9]] ^ Xtime2Sbox[state[14]] ^ Xtime3Sbox[state[3]];
        tmp[7] = Xtime3Sbox[state[4]] ^ Sbox[state[9]] ^ Sbox[state[14]] ^ Xtime2Sbox[state[3]];

        // mixing column 2
        tmp[8] = Xtime2Sbox[state[8]] ^ Xtime3Sbox[state[13]] ^ Sbox[state[2]] ^ Sbox[state[7]];
        tmp[9] = Sbox[state[8]] ^ Xtime2Sbox[state[13]] ^ Xtime3Sbox[state[2]] ^ Sbox[state[7]];
        tmp[10] = Sbox[state[8]] ^ Sbox[state[13]] ^ Xtime2Sbox[state[2]] ^ Xtime3Sbox[state[7]];
        tmp[11] = Xtime3Sbox[state[8]] ^ Sbox[state[13]] ^ Sbox[state[2]] ^ Xtime2Sbox[state[7]];

        // mixing column 3
        tmp[12] = Xtime2Sbox[state[12]] ^ Xtime3Sbox[state[1]] ^ Sbox[state[6]] ^ Sbox[state[11]];
        tmp[13] = Sbox[state[12]] ^ Xtime2Sbox[state[1]] ^ Xtime3Sbox[state[6]] ^ Sbox[state[11]];
        tmp[14] = Sbox[state[12]] ^ Sbox[state[1]] ^ Xtime2Sbox[state[6]] ^ Xtime3Sbox[state[11]];
        tmp[15] = Xtime3Sbox[state[12]] ^ Sbox[state[1]] ^ Sbox[state[6]] ^ Xtime2Sbox[state[11]];

        state.position = 0;
        state.writeBytes(tmp, 0, Nb * 4);
    }

    // restore and un-mix each row in a column

    private function invMixSubColumns():Void {
        tmp.length = 0;
        var i:Int32;

        // restore column 0
        tmp[0] = XtimeE[state[0]] ^ XtimeB[state[1]] ^ XtimeD[state[2]] ^ Xtime9[state[3]];
        tmp[5] = Xtime9[state[0]] ^ XtimeE[state[1]] ^ XtimeB[state[2]] ^ XtimeD[state[3]];
        tmp[10] = XtimeD[state[0]] ^ Xtime9[state[1]] ^ XtimeE[state[2]] ^ XtimeB[state[3]];
        tmp[15] = XtimeB[state[0]] ^ XtimeD[state[1]] ^ Xtime9[state[2]] ^ XtimeE[state[3]];

        // restore column 1
        tmp[4] = XtimeE[state[4]] ^ XtimeB[state[5]] ^ XtimeD[state[6]] ^ Xtime9[state[7]];
        tmp[9] = Xtime9[state[4]] ^ XtimeE[state[5]] ^ XtimeB[state[6]] ^ XtimeD[state[7]];
        tmp[14] = XtimeD[state[4]] ^ Xtime9[state[5]] ^ XtimeE[state[6]] ^ XtimeB[state[7]];
        tmp[3] = XtimeB[state[4]] ^ XtimeD[state[5]] ^ Xtime9[state[6]] ^ XtimeE[state[7]];

        // restore column 2
        tmp[8] = XtimeE[state[8]] ^ XtimeB[state[9]] ^ XtimeD[state[10]] ^ Xtime9[state[11]];
        tmp[13] = Xtime9[state[8]] ^ XtimeE[state[9]] ^ XtimeB[state[10]] ^ XtimeD[state[11]];
        tmp[2] = XtimeD[state[8]] ^ Xtime9[state[9]] ^ XtimeE[state[10]] ^ XtimeB[state[11]];
        tmp[7] = XtimeB[state[8]] ^ XtimeD[state[9]] ^ Xtime9[state[10]] ^ XtimeE[state[11]];

        // restore column 3
        tmp[12] = XtimeE[state[12]] ^ XtimeB[state[13]] ^ XtimeD[state[14]] ^ Xtime9[state[15]];
        tmp[1] = Xtime9[state[12]] ^ XtimeE[state[13]] ^ XtimeB[state[14]] ^ XtimeD[state[15]];
        tmp[6] = XtimeD[state[12]] ^ Xtime9[state[13]] ^ XtimeE[state[14]] ^ XtimeB[state[15]];
        tmp[11] = XtimeB[state[12]] ^ XtimeD[state[13]] ^ Xtime9[state[14]] ^ XtimeE[state[15]];

        for (i in 0 ... 4 * Nb) state[i] = InvSbox[tmp[i]];
    }

    // encrypt/decrypt columns of the key

    private function addRoundKey(key:ByteArray, offset:Int32):Void {
        for (idx in 0...16) state[idx] ^= key[idx + offset];
    }

    static private function initOnce() {
        if (Sbox != null) return;

        Sbox = new ByteArray();
        InvSbox = new ByteArray();
        Xtime2Sbox = new ByteArray();
        Xtime3Sbox = new ByteArray();
        Xtime2 = new ByteArray();
        Xtime9 = new ByteArray();
        XtimeB = new ByteArray();
        XtimeD = new ByteArray();
        XtimeE = new ByteArray();
        Rcon = new ByteArray();

        for (i in 0...256) Sbox[i] = AESKeyTables._Sbox[i];
        for (i in 0...256) InvSbox[i] = AESKeyTables._InvSbox[i];
        for (i in 0...256) Xtime2Sbox[i] = AESKeyTables._Xtime2Sbox[i];
        for (i in 0...256) Xtime3Sbox[i] = AESKeyTables._Xtime3Sbox[i];
        for (i in 0...256) Xtime2[i] = AESKeyTables._Xtime2[i];
        for (i in 0...256) Xtime9[i] = AESKeyTables._Xtime9[i];
        for (i in 0...256) XtimeB[i] = AESKeyTables._XtimeB[i];
        for (i in 0...256) XtimeD[i] = AESKeyTables._XtimeD[i];
        for (i in 0...256) XtimeE[i] = AESKeyTables._XtimeE[i];
        for (i in 0...AESKeyTables._Rcon.length) Rcon[i] = AESKeyTables._Rcon[i];
    }

    public function toString():String {
        return "aes" + (8 * keyLength);
    }
}
