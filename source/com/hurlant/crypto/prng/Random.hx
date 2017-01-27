/**
 * Random
 * 
 * An ActionScript 3 implementation of a Random Number Generator
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The jsbn library, Copyright (c) 2003-2005 Tom Wu
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.prng;

import haxe.Int32;
import com.hurlant.util.ArrayUtil;
import com.hurlant.util.ByteArray;
import com.hurlant.util.Memory;

class Random implements IRandom {
    private var state:IPRNG;
    private var ready:Bool = false;
    private var pool:ByteArray;
    private var psize:Int32;
    private var pptr:Int32;
    private var seeded:Bool = false;

    public function new(prng:Void -> IPRNG = null) {
        if (prng == null) prng = function() { return new ARC4(); };
        state = prng();
        psize = state.getPoolSize();
        pool = new ByteArray();
        pptr = 0;
        while (pptr < psize) {
            var t:Int32 = Std.random(0xFFFF + 1);
            pool[pptr++] = (t >>> 8) & 0xFF;
            pool[pptr++] = (t >>> 0) & 0xFF;
        }
        pptr = 0;
        seed();
    }

    public function seed(x:Int32 = 0):Void {
        if (x == 0) x = Std.int(Date.now().getTime());
        pool[pptr++] ^= (x >> 0) & 0xFF;
        pool[pptr++] ^= (x >> 8) & 0xFF;
        pool[pptr++] ^= (x >> 16) & 0xFF;
        pool[pptr++] ^= (x >> 24) & 0xFF;
        pptr %= psize;
        seeded = true;
    }

    public function autoSeed():Void {
        var data: ByteArray = SecureRandom.getSecureRandomBytes(512);
        while (data.bytesAvailable >= 4) seed(data.readUnsignedInt());
    }

    public function nextBytes(buffer:ByteArray, length:Int32):Void {
        while (length-- > 0) buffer.writeByte(nextByte());
    }

    public function getRandomBytes(length:Int32):ByteArray {
        var buffer = new ByteArray();
        while (length-- > 0) buffer.writeByte(nextByte());
        buffer.position = 0;
        return buffer;
    }

    static public function getStaticRandomBytes(length:Int32, prng:Void -> IPRNG = null):ByteArray {
        return new Random(prng).getRandomBytes(length);
    }

    public function nextByte():Int32 {
        if (!ready) {
            if (!seeded) autoSeed();
            state.init(pool);
            pool.length = 0;
            pptr = 0;
            ready = true;
        }
        return state.next();
    }

    public function dispose():Void {
        ArrayUtil.secureDisposeByteArray(pool);
        pool = null;
        state.dispose();
        state = null;
        psize = 0;
        pptr = 0;
        Memory.gc();
    }

    public function toString():String {
        return "random-" + state.toString();
    }
}

