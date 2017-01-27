package com.hurlant.util;
import haxe.Int32;
class Std2 {
    static public function modulo(x:Int, y:Int):Int {
        return ((x % y) + y) % y;
    }

    static public function parseHex(value:String):Int32 {
        var out:Int32 = 0;
        //trace(value);
        for (n in 0 ... value.length) {
            var c = value.charAt(n);
            var cc = value.charCodeAt(n);
            var digit = CType.getDigit(cc);
            if (digit < 0 || digit >= 16) throw new Error('Invalid digit $digit');

            out = out << 4;
            out |= digit;
        }
        return out;
    }

    static public function parseInt(value:String, radix:Int32 = 10):Int32 {
        if (value.substr(0, 1) == '-') return -parseInt(value.substr(1), radix);
        if (radix == 16) return parseHex(value);
        var out:Int32 = 0;
        //trace(value);
        for (n in 0 ... value.length) {
            var c = value.charAt(n);
            var cc = value.charCodeAt(n);
            var digit = CType.getDigit(cc);
            if (digit < 0 || digit >= radix) throw new Error('Invalid digit $digit');
            out *= radix;
            out += digit;
        }
        return out;
    }

    static public function toStringHex(value:Int32):String {
        if (value == 0) return '0';
        var out = '';
        while (value != 0) {
            var c = CType.DIGITS.charAt(value & 0xF);
            out = c + out;
            value = value >>> 4;
        }
        return out;
    }

    static public function string(value:Int32, radix:Int32):String {
        if (value < 0) return '-' + string(-value, radix);
        if (value == 0) return '0';
        var out = '';
        while (value > 0) {
            var c = CType.DIGITS.charAt(value % radix);
            out = c + out;
            value = Std.int(value / radix);
        }
        return out;
    }

    static public function min3(a:Float, b:Float, c:Float):Float {
        return Math.min(Math.min(a, b), c);
    }

    static public function bswap32(a:Int32):Int32 {
        return ((a & 0xFF) << 24) | ((a & 0x0000ff00) << 8) | ((a & 0x00ff0000) >>> 8) | ((a >>> 24) & 0xFF);
    }

    static public function bswap24(a:Int32):Int32 {
        var v0 = (a >>> 0) & 0xFF;
        var v1 = (a >>> 8) & 0xFF;
        var v2 = (a >>> 16) & 0xFF;
        return (v2 << 0) | (v1 << 8) | (v0 << 16);
    }

    static public function bswap16(value:Int32):Int32 {
        return ((value & 0xFF) << 8) | ((value >>> 8) & 0xFF);
    }

    /*
     * Bitwise rotate a 32-bit number to the right.
     */

    static public function rrol(num:Int32, cnt:Int32):Int32 {
        return (num << (32 - cnt)) | (num >>> cnt);
    }

    /*
     * Bitwise rotate a 32-bit number to the left.
     */

    static public function rol(num:Int32, cnt:Int32):Int32 {
        return (num << cnt) | (num >>> (32 - cnt));
    }


    /**
     *
     * @param x
     * @return number of 1 bits in x
     *
     */

    static public function cbit(x:Int32):Int32 {
        x = x - ((x >>> 1) & 0x55555555);
        x = (x & 0x33333333) + ((x >>> 2) & 0x33333333);
        x = (x + (x >>> 4)) & 0x0f0f0f0f;
        x = x + (x >>> 8);
        x = x + (x >>> 16);
        return x & 0x3f;
    }


    /**
     *
     * @param x
     * @return index of lower 1-bit in x, x < 2^31
     *
     */

    static public function lbit(x:Int32):Int32 {
        if (x == 0) return -1;
        var r = 0;
        if ((x & 0xffff) == 0) { x = x >> 16; r += 16; }
        if ((x & 0x00ff) == 0) { x = x >> 8; r += 8; }
        if ((x & 0x000f) == 0) { x = x >> 4; r += 4; }
        if ((x & 0x0003) == 0) { x = x >> 2; r += 2; }
        if ((x & 0x0001) == 0) { x = x >> 0; r += 1; }
        return r;
    }

    /**
     * returns bit length of the integer x
     */

    static public function nbits(x:Int32):Int32 {
        var r:Int32 = 1;
        var t:Int32;
        if ((t = x >>> 16) != 0) { x = t; r += 16; }
        if ((t = x >> 8) != 0) { x = t; r += 8; }
        if ((t = x >> 4) != 0) { x = t; r += 4; }
        if ((t = x >> 2) != 0) { x = t; r += 2; }
        if ((t = x >> 1) != 0) { x = t; r += 1; }
        return r;
    }

    static public function op_and(x:Int32, y:Int32):Int32 {
        return x & y;
    }

    static public function op_or(x:Int32, y:Int32):Int32 {
        return x | y;
    }

    static public function op_xor(x:Int32, y:Int32):Int32 {
        return x ^ y;
    }

    static public function op_andnot(x:Int32, y:Int32):Int32 {
        return x & ~y;
    }

    static public function sx8(v:Int32):Int32 {
        return (v << 24) >> 24;
    }

    static public function sx16(v:Int32):Int32 {
        return (v << 16) >> 16;
    }

    static public function roundUp(numToRound:Int32, multiple:Int32) {
        var isPositive = (numToRound >= 0) ? 1 : 0;
        return Std.int((numToRound + isPositive * (multiple - 1)) / multiple) * multiple;
    }
}