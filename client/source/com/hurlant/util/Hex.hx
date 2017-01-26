/**
 * Hex
 *
 * Utility class to convert Hex strings to ByteArray or String types.
 * Copyright (c) 2007 Henri Torgemane
 *
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util;

import haxe.io.Bytes;
import haxe.Int32;
import com.hurlant.util.ByteArray;

class Hex {
    /**
     * Generates byte-array from given hexadecimal string
     *
     * Supports straight and colon-laced hex (that means 23:03:0e:f0, but *NOT* 23:3:e:f0)
     * The first nibble (hex digit) may be omitted.
     * Any whitespace characters are ignored.
     */
    public static function toArray(hex:String):ByteArray {
        hex = new EReg('^0x|\\s|:', "gm").replace(hex, "");
        if ((hex.length & 1) == 1) hex = "0" + hex;

        var a = Bytes.alloc(Std.int(hex.length / 2));
        for (i in 0 ... a.length) {
            a.set(i, Std2.parseInt(hex.substr(i * 2, 2), 16));
        }
        return a;
    }

    /**
     * Generates lowercase hexadecimal string from given byte-array
     */

    public static function fromArray(array:ByteArray, colons:Bool = false):String {
        var s:String = "";
        for (i in 0...array.length) {
            s += ("0" + Std2.string(array[i], 16)).substr(-2, 2);
            if (colons) if (i < array.length - 1) s += ":";
        }
        return s;
    }


    /**
     * Generates string from given hexadecimal string
     */
    public static function toString(hex:String, charSet:String = "utf-8"):String {
        var a:ByteArray = toArray(hex);
        return a.readMultiByte(a.length, charSet);
    }

    /**
     * Convenience method for generating string using iso-8859-1
     */

    public static function toRawString(hex:String):String {
        return toString(hex, "iso-8859-1");
    }

    /**
     * Generates hexadecimal string from given string
     */

    public static function fromString(str:String, colons:Bool = false, charSet:String = "utf-8"):String {
        var a:ByteArray = new ByteArray();
        a.writeMultiByte(str, charSet);
        a.position = 0;
        return fromArray(a, colons);
    }

    /**
     * Convenience method for generating hexadecimal string using iso-8859-1
     */

    public static function fromRawString(str:String, colons:Bool = false):String {
        return fromString(str, colons, "iso-8859-1");
    }
}

