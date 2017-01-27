package com.hurlant.util.asn1.type;

import haxe.Int32;
import com.hurlant.util.ByteArray;

class OIDType extends ASN1Type {
    public var oid:String = null;

    public function new(s:String = null) {
        super(ASN1Type.OID);
        oid = s;
    }

    public function toString():String {
        return oid;
    }

    /**
     * I'm tempted to return fully defined OIDType objects
     * Altough that's a little bit weird.
     *
     * @param s
     * @param length
     * @return
     *
     */
    override private function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        var p:Int32 = s.position;
        // parse stuff
        // first byte = 40*value1 + value2
        var o:Int32 = s.readUnsignedByte();
        var left:Int32 = length - 1;
        var a:Array<Int> = [];
        a.push(Std.int(o / 40));
        a.push(Std.int(o % 40));
        var v:Int32 = 0;
        while (left-- > 0) {
            o = s.readUnsignedByte();
            var last:Bool = (o & 0x80) == 0;
            o &= 0x7f;
            v = v * 128 + o;
            if (last) {
                a.push(v);
                v = 0;
            }
        }
        var str:String = a.join(".");
        if (oid != null) {
            if (oid == str) {
                return this.clone();
            } else {
                s.position = p;
                return null;
            }
        } else {
            return new OIDType(str);
        }
    }
}
