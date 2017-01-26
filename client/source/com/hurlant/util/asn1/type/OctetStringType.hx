package com.hurlant.util.asn1.type;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class OctetStringType extends ASN1Type {
    public function new() {
        super(ASN1Type.OCTET_STRING);
    }

    override private function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        var b:ByteArray = new ByteArray();
        s.readBytes(b, 0, length);
        return b;
    }
}
