package com.hurlant.crypto.encoding;

import com.hurlant.util.Endian;
class Charsets {
    static public var UTF8(default, null):Charset = new UTF8();
    static public var UTF16_LE(default, null):Charset = new UTF16(Endian.LITTLE_ENDIAN);
    static public var UTF16_BE(default, null):Charset = new UTF16(Endian.BIG_ENDIAN);
    static public var UTF16(default, null):Charset = UTF16_LE;
    static public var UCS2(default, null):Charset = UTF16_LE;
    static public var ASCII(default, null):Charset = new ASCII();
    static public var LATIN1(default, null):Charset = ASCII;
    static public var ISO_8859_1(default, null):Charset = ASCII;

    static public function fromString(name:String):Charset {
        return switch (name.toLowerCase()) {
            case 'utf8', "utf-8": UTF8;
            case 'utf16', "utf-16", "ucs2", "ucs-2": UTF16;
            case 'utf16le', "utf-16le", "ucs2le", "ucs-2le": UTF16_LE;
            case 'utf16be', "utf-16be", "ucs2be", "ucs-2be": UTF16_BE;
            case 'ascii': ASCII;
            case "iso-8859-1", "latin1": ASCII; // @TODO
            default: throw 'Not supported encoding "$name"';
        }
    }
}