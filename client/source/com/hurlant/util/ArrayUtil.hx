package com.hurlant.util;
import haxe.Int32;
import com.hurlant.crypto.prng.Random;
class ArrayUtil {
    public static function equals(a1:ByteArray, a2:ByteArray):Bool {
        if (a1.length != a2.length) return false;
        for (i in 0 ... a1.length) if (a1.get(i) != a2.get(i)) return false;
        return true;
    }

    public static function secureDisposeIntArray(k:Array<Int32>) {
        if (k == null) return;
        var r = new Random();
        for (i in 0...k.length) k[i] = r.nextByte();
    }

    static public function secureDisposeByteArray(ba:ByteArray) {
        if (ba == null) return;
        // @TODO: Not use ByteArray, since ByteArray can grow and it realloc buffers copying content
        // @TODO: Instead allocate a fixed size buffer
        for (i in 0...ba.length) ba[i] = Std.random(256);
        ba.length = 0;
    }

    /**
     * This function xor to ByteArrays and the delivers the result in a new
     * ByteArray instance with the length __len__.
     */
    public static function xorByteArray(b1:ByteArray, b1start:Int32, b2:ByteArray, b2start:Int32, len:Int32):ByteArray {
        var res = new ByteArray();
        res.length = len;
        for (loop in 0 ... len) {
            res[loop] = b1[b1start + loop] ^ b2[b2start + loop];
        }
        return res;
    }
}
