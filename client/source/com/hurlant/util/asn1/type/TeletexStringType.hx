package com.hurlant.util.asn1.type;

import haxe.Int32;

class TeletexStringType extends StringType {
    public function new(size1:Int32 = Int.MAX_VALUE, size2:Int32 = 0) {
        super(ASN1Type.TELETEX_STRING, size1, size2);
    }
}
