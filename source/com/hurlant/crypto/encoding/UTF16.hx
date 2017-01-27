package com.hurlant.crypto.encoding;

import com.hurlant.util.Endian;
import haxe.io.Bytes;
import com.hurlant.util.ByteArray;

class UTF16 implements Charset {
    // To assist in recognizing the byte order of code units,
    // UTF-16 allows a Byte Order Mark (BOM), a code point with the value U+FEFF,
    // to precede the first actual coded value.
    public var endian:Endian;

    public function new(endian:Endian) {
        this.endian = endian;
    }

    public function encode(input:String):Bytes {
        var out = new ByteArray();
        out.endian = endian;
        for (n in 0 ... input.length) out.writeShort(input.charCodeAt(n));
        out.position = 0;
        return out;
    }

    public function decode(input:Bytes):String {
        var i = ByteArray.fromBytes(input);
        i.endian = endian;
        var out = '';
        while (i.bytesAvailable > 0) {
            // @TODO: CHECK BOM!
            out += String.fromCharCode(i.readUnsignedShort());
        }
        return out;
    }
}