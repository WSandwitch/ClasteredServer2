package com.hurlant.util.asn1.type;


import haxe.Int32;
class BooleanType extends ASN1Type {
    public function new() {
        super(ASN1Type.BOOLEAN);
    }

    private override function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        return s.readUnsignedByte();
    }
}
