package com.hurlant.crypto.extra;

import com.hurlant.crypto.prng.IRandom;
import haxe.Int32;
import com.hurlant.util.Bits;
import com.hurlant.util.Hex;
import com.hurlant.crypto.prng.Random;
import com.hurlant.util.Error;
import haxe.io.Bytes;
import com.hurlant.util.ByteArray;

// https://en.wikipedia.org/wiki/Universally_unique_identifier
// https://tools.ietf.org/html/rfc4122
// xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx
// N = Variant
// M = Version
class UUID {
    private var bytes:Bytes;

    public function new(bytes:Bytes) {
        if (bytes.length != 16) throw new Error('UUID must have 16 bytes by has ${bytes.length}');
        this.bytes = bytes;
    }

    static public function fromParts(a:Int32, b:Int32, c:Int32, v0:Int32, v1:Int32, v2:Int32, v3:Int32, v4:Int32, v5:Int32, v6:Int32, v7:Int32):UUID {
        var ba = new ByteArray();
        ba.writeUnsignedInt(a);
        ba.writeShort(b);
        ba.writeShort(c);
        ba.writeByte(v0);
        ba.writeByte(v1);
        ba.writeByte(v2);
        ba.writeByte(v3);
        ba.writeByte(v4);
        ba.writeByte(v5);
        ba.writeByte(v6);
        ba.writeByte(v7);
        return new UUID(ba);
    }

    static public function fromString(str:String):UUID {
        return new UUID(Hex.toArray(StringTools.replace(str, '-', '')));
    }

    static public function generateRandom(random:IRandom = null):UUID {
        var bytes = ByteArray.fromBytes(random.getRandomBytes(16));
        bytes[8] = Bits.insert(bytes[8], 6, 2, 2);
        bytes[6] = Bits.insert(bytes[6], 4, 4, 4);
        return new UUID(bytes);
    }

    public function getBytes():Bytes {
        return ByteArray.cloneBytes(this.bytes);
    }

    public function getInts():Array<Int32> {
        return ByteArray.fromBytes(this.bytes).toBytesArray();
    }

    // https://tools.ietf.org/html/rfc4122#section-4.1.1

    public function getVariant():Variant {
        var M = bytes.get(8);
        if (Bits.extract(M, 7, 1) == 0) return Variant.Reserved1;
        if (Bits.extract(M, 6, 1) == 0) return Variant.RFC4122;
        if (Bits.extract(M, 5, 1) == 0) return Variant.Microsoft;
        return Variant.Reserved2;
    }

    // https://tools.ietf.org/html/rfc4122#section-4.1.3

    public function getVersion():Int32 {
        var N = bytes.get(6);
        return Bits.extract(N, 4, 4);
    }

    public function toString():String {
        var hex = Hex.fromArray(this.bytes);
        return hex.substr(0, 8) + "-" + hex.substr(8, 4) + "-" + hex.substr(12, 4) + "-" + hex.substr(16, 4) + "-" + hex.substr(20);
    }
}

enum Variant {
    Reserved1;
    RFC4122;
    Microsoft;
    Reserved2;
}