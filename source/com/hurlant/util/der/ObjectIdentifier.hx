/**
 * ObjectIdentifier
 * 
 * An ASN1 type for an ObjectIdentifier
 * We store the oid in an Array.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;

import haxe.Int32;
import com.hurlant.util.Error;

import com.hurlant.util.ByteArray;

class ObjectIdentifier implements IAsn1Type {
    private var type:Int32;
    private var len:Int32;
    private var oid:Array<Int>;

    public function new(type:Int32 = 0, length:Int32 = 0, b:Dynamic = null) {
        this.type = type;
        this.len = length;
        if (Std.is(b, ByteArrayData)) {
            parse(cast(b, ByteArray));
        } else if (Std.is(b, String)) {
            generate(cast(b, String));
        } else {
            throw new Error("Invalid call to new ObjectIdentifier");
        }
    }

    private function generate(s:String):Void {
        oid = [for (n in s.split(".")) Std2.parseInt(n)];
    }

    private function parse(b:ByteArray):Void {
        // parse stuff
        // first byte = 40*value1 + value2
        var o:Int32 = b.readUnsignedByte();
        var a:Array<Int32> = [];
        a.push(Std.int(o / 40));
        a.push(Std.int(o % 40));
        var v:Int32 = 0;
        while (b.bytesAvailable > 0) {
            o = b.readUnsignedByte();
            var last:Bool = (o & 0x80) == 0;
            o &= 0x7f;
            v = v * 128 + o;
            if (last) {
                a.push(v);
                v = 0;
            }
        }
        oid = a;
    }

    public function getLength():Int32 {
        return len;
    }

    public function getType():Int32 {
        return type;
    }

    public function toDER():ByteArray {
        var tmp:Array<Int32> = [];
        tmp[0] = oid[0] * 40 + oid[1];
        for (i in 2...oid.length) {
            var v:Int32 = oid[i];
            if (v < 128) {
                tmp.push(v);
            }
            else if (v < 128 * 128) {
                tmp.push((v >> 7) | 0x80);
                tmp.push(v & 0x7f);
            }
            else if (v < 128 * 128 * 128) {
                tmp.push((v >> 14) | 0x80);
                tmp.push((v >> 7) & 0x7f | 0x80);
                tmp.push(v & 0x7f);
            }
            else if (v < 128 * 128 * 128 * 128) {
                tmp.push((v >> 21) | 0x80);
                tmp.push((v >> 14) & 0x7f | 0x80);
                tmp.push((v >> 7) & 0x7f | 0x80);
                tmp.push(v & 0x7f);
            }
            else {
                throw new Error("OID element bigger than we thought. :(");
            }
        }
        len = tmp.length;
        if (type == 0) {
            type = 6;
        }
        tmp.unshift(len); // assume length is small enough to fit here.
        tmp.unshift(type);
        var b:ByteArray = new ByteArray();
        for (i in 0...tmp.length) {
            b[i] = tmp[i];
        }
        return b;
    }

    public function toString():String {
        return DER.indent + oid.join(".");
    }

    public function dump():String {
        return "OID[" + type + "][" + len + "][" + toString() + "]";
    }
}
