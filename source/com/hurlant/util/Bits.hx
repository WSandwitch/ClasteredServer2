package com.hurlant.util;

import haxe.Int32;

class Bits {
    static public function mask(count:Int32):Int32 {
        return (1 << count) - 1;
    }

    static public function extract(v:Int32, offset:Int32, count:Int32):Int32 {
        return (v >>> offset) & mask(count);
    }

    static public function extractBit(v:Int32, offset:Int32):Bool {
        return ((v >>> offset) & 1) != 0;
    }

    static public function clear(v:Int32, offset:Int32, count:Int32):Int32 {
        return v & ~(mask(count) << offset);
    }

    static public function insert(v:Int32, offset:Int32, count:Int32, value:Int32):Int32 {
        var mask = Bits.mask(count);
        v &= clear(v, offset, count);
        v |= (value & mask) << offset;
        return v;
    }
}