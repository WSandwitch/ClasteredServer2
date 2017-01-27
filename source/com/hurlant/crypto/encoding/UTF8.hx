package com.hurlant.crypto.encoding;

import haxe.io.Bytes;
import com.hurlant.util.ByteArray;
class UTF8 implements Charset {
    public function new() {
    }

    public function encode(input:String):Bytes {
        var out = new ByteArray();
        for (n in 0 ... input.length) {
            var c = input.charCodeAt(n);
            if ((c & 0xFFFFFF80) == 0) { // 1-byte sequence
                out.writeByte(c);
            } else if ((c & 0xFFFFF800) == 0) { // 2-byte sequence
                out.writeByte(((c >> 6) & 0x1F) | 0xC0);
                out.writeByte(((c >> 0) & 0x3F) | 0x80);
            } else if ((c & 0xFFFF0000) == 0) { // 3-byte sequence
                //checkScalarValue(codePoint);
                out.writeByte((((c >> 12) & 0x0F) | 0xE0));
                out.writeByte((((c >>  6) & 0x3F) | 0x80));
                out.writeByte((((c >>  0) & 0x3F) | 0x80));
            } else if ((c & 0xFFE00000) == 0) { // 4-byte sequence
                out.writeByte((((c >> 18) & 0x07) | 0xF0));
                out.writeByte((((c >> 12) & 0x3F) | 0x80));
                out.writeByte((((c >>  6) & 0x3F) | 0x80));
                out.writeByte((((c >>  0) & 0x3F) | 0x80));
            }
        }
        out.position = 0;
        return out;
    }

    public function decode(input:Bytes):String {
        var bytes = ByteArray.fromBytes(input);
        var out = '';

        while (bytes.bytesAvailable > 0) {
            var byte1 = bytes.readUnsignedByte();
            var codePoint = 0;

            // 1-byte sequence (no continuation bytes)
            if ((byte1 & 0x80) == 0) {
                codePoint = byte1;
            }

            // 2-byte sequence
            else if ((byte1 & 0xE0) == 0xC0) {
                var byte2 = bytes.readUnsignedByte() & 0x7F;
                codePoint = ((byte1 & 0x1F) << 6) | byte2;
                if (codePoint < 0x80) throw 'Invalid continuation byte';
            }

            // 3-byte sequence (may include unpaired surrogates)
            else if ((byte1 & 0xF0) == 0xE0) {
                var byte2 = bytes.readUnsignedByte() & 0x7F;
                var byte3 = bytes.readUnsignedByte() & 0x7F;
                codePoint = ((byte1 & 0x0F) << 12) | (byte2 << 6) | byte3;
                if (codePoint < 0x0800) throw 'Invalid continuation byte';
                //checkScalarValue(codePoint);
            }

            // 4-byte sequence
            else if ((byte1 & 0xF8) == 0xF0) {
                var byte2 = bytes.readUnsignedByte() & 0x7F;
                var byte3 = bytes.readUnsignedByte() & 0x7F;
                var byte4 = bytes.readUnsignedByte() & 0x7F;
                codePoint = ((byte1 & 0x0F) << 0x12) | (byte2 << 0x0C) | (byte3 << 0x06) | byte4;
                if (codePoint < 0x010000 || codePoint > 0x10FFFF) throw 'Invalid continuation byte';
            }

            out += String.fromCharCode(codePoint);
        }
        return out;
    }
}