package com.hurlant.crypto.extra;

import com.hurlant.util.CType;
import com.hurlant.util.Std2;
import com.hurlant.util.ByteArray;
import haxe.io.Bytes;

/*
 * http://www.rot13.com/
 * ROT13 is a simple variation of the Caesar cipher, developed in ancient Rome.
 */
class ROT {
    static public function rotateString(input:String, rotationOffset:Int):String {
        var out = '';
        for (n in 0 ... input.length) {
            out += String.fromCharCode(rotate(input.charCodeAt(n), rotationOffset));
        }
        return out;
    }

    static public function rotateBytesInplace(inout:Bytes, rotationOffset:Int):Void {
        for (n in 0 ... inout.length) {
            inout.set(n, rotate(inout.get(n), rotationOffset));
        }
    }

    static public function rotateBytes(input:Bytes, rotationOffset:Int):Bytes {
        var out = ByteArray.cloneBytes(input);
        rotateBytesInplace(out, rotationOffset);
        return out;
    }

    static private function rotate(charCode:Int, rotationOffset:Int):Int {
        if (CType.isLowerAlpha(charCode)) {
            return 'a'.code + Std2.modulo((charCode - 'a'.code) + rotationOffset, 26);
        } else if (CType.isUpperAlpha(charCode)) {
            return 'A'.code + Std2.modulo((charCode - 'A'.code) + rotationOffset, 26);
        } else {
            return charCode;
        }
    }
}