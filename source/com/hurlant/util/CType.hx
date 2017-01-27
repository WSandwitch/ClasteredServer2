package com.hurlant.util;
import haxe.Int32;
class CType {
    static public var DIGITS = '0123456789abcdefghijklmnopqrstuvwxyz';

    static public function getDigit(charCode:Int32):Int32 {
        if (isDigit(charCode)) return (charCode - '0'.code) + 0;
        if (isLowerAlpha(charCode)) return (charCode - 'a'.code) + 10;
        if (isUpperAlpha(charCode)) return (charCode - 'A'.code) + 10;
        return -1;
    }

    static public function isDigit(charCode:Int32):Bool {
        return (charCode >= '0'.code && charCode <= '9'.code);
    }

    static public function isAlpha(charCode:Int32):Bool {
        return isUpperAlpha(charCode) || isLowerAlpha(charCode);
    }

    static public function isUpperAlpha(charCode:Int32):Bool {
        return ((charCode >= 'A'.code) && (charCode <= 'Z'.code));
    }

    static public function isLowerAlpha(charCode:Int32):Bool {
        return ((charCode >= 'a'.code) && (charCode <= 'z'.code));
    }
}