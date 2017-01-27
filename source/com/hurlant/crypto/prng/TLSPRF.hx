/**
 * TLSPRF
 * 
 * An ActionScript 3 implementation of a pseudo-random generator
 * that follows the TLS specification
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.prng;


import haxe.Int32;
import com.hurlant.util.ByteArray;
import com.hurlant.crypto.hash.HMAC;
import com.hurlant.crypto.hash.MD5;
import com.hurlant.crypto.hash.SHA1;
import com.hurlant.util.Memory;
import com.hurlant.util.IDataOutput;

/**
 * There's "Random", and then there's TLS Random.
 * .
 * Still Pseudo-random, though.
 */
class TLSPRF {
    // XXX WAY TOO MANY STRUCTURES HERE

    private var seed:ByteArray; // seed
    private var s1:ByteArray; // P_MD5's secret
    private var s2:ByteArray; // P_SHA-1's secret
    private var a1:ByteArray; // HMAC_MD5's A
    private var a2:ByteArray; // HMAC_SHA1's A
    private var p1:ByteArray; // Pool for P_MD5
    private var p2:ByteArray; // Pool for P_SHA1
    private var d1:ByteArray; // Data for HMAC_MD5
    private var d2:ByteArray; // Data for HMAC_SHA1

    private var hmac_md5:HMAC;
    private var hmac_sha1:HMAC;

    public function new(secret:ByteArray, label:String, seed:ByteArray) {
        var l = Math.ceil(secret.length / 2);
        var s1 = new ByteArray();
        var s2 = new ByteArray();
        s1.writeBytes(secret, 0, l);
        s2.writeBytes(secret, secret.length - l, l);
        var s:ByteArray = new ByteArray();
        s.writeUTFBytes(label);
        s.writeBytes(seed);
        this.seed = s;
        this.s1 = s1;
        this.s2 = s2;
        hmac_md5 = new HMAC(new MD5());
        hmac_sha1 = new HMAC(new SHA1());

        this.a1 = hmac_md5.compute(s1, this.seed);
        this.a2 = hmac_sha1.compute(s2, this.seed);

        p1 = new ByteArray();
        p2 = new ByteArray();

        d1 = new ByteArray();
        d2 = new ByteArray();
        d1.position = MD5.HASH_SIZE;
        d1.writeBytes(this.seed);
        d2.position = SHA1.HASH_SIZE;
        d2.writeBytes(this.seed);
    }

    // XXX HORRIBLY SLOW. REWRITE.

    public function nextBytes(buffer:IDataOutput, length:Int32):Void {
        while (length-- > 0) buffer.writeByte(nextByte());
    }

    public function getNextBytes(length:Int32):ByteArray {
        var out = new ByteArray();
        nextBytes(out, length);
        out.position = 0;
        return out;
    }

    public function nextByte():Int32 {
        if (p1.bytesAvailable == 0) more_md5();
        if (p2.bytesAvailable == 0) more_sha1();
        return p1.readUnsignedByte() ^ p2.readUnsignedByte();
    }

    public function dispose():Void {
        seed = dba(seed);
        s1 = dba(s1);
        s2 = dba(s2);
        a1 = dba(a1);
        a2 = dba(a2);
        p1 = dba(p1);
        p2 = dba(p2);
        d1 = dba(d1);
        d2 = dba(d2);
        hmac_md5.dispose();
        hmac_md5 = null;
        hmac_sha1.dispose();
        hmac_sha1 = null;
        Memory.gc();
    }

    private function dba(ba:ByteArray):ByteArray {
        for (i in 0...ba.length) ba[i] = 0;
        ba.length = 0;
        return null;
    }

    private function more_md5():Void {
        d1.position = 0;
        d1.writeBytes(a1);
        var p:Int32 = p1.position;
        var more:ByteArray = hmac_md5.compute(s1, d1);
        a1 = hmac_md5.compute(s1, a1);
        p1.writeBytes(more);
        p1.position = p;
    }

    private function more_sha1():Void {
        d2.position = 0;
        d2.writeBytes(a2);
        var p:Int32 = p2.position;
        var more:ByteArray = hmac_sha1.compute(s2, d2);
        a2 = hmac_sha1.compute(s2, a2);
        p2.writeBytes(more);
        p2.position = p;
    }

    public function toString():String {
        return "tls-prf";
    }
}