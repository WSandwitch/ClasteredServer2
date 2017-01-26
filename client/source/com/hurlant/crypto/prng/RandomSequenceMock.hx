package com.hurlant.crypto.prng;

import com.hurlant.crypto.prng.RandomSequenceMock;
import com.hurlant.util.ByteArray;
import haxe.io.Bytes;
import haxe.Int32;

class RandomSequenceMock implements IRandom {
    public var value:Bytes;
    private var offset:Int;

    public function new(value:Bytes, offset:Int = 0) {
        this.value = value;
        this.offset = offset;
    }

    static public function byte(value:Int):RandomSequenceMock {
        return new RandomSequenceMock(ByteArray.fromBytesArray([value]));
    }

    public function getRandomBytes(length:Int32):ByteArray {
        var out = Bytes.alloc(length);
        for (n in 0 ... length) out.set(n, this.value.get(this.offset++ % this.value.length));
        return out;
    }
}