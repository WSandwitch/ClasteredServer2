package com.hurlant.util.asn1.type;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class NullType extends ASN1Type {
    public function new() {
        super(ASN1Type.NULL);
    }

    override private function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        return "NULL";
    }
}
