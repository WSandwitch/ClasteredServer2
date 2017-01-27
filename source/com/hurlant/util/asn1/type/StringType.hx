package com.hurlant.util.asn1.type;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class StringType extends ASN1Type {
    public var size1:Int32;public var size2:Int32;

    public function new(tag:Int32, size1:Int32 = Int.MAX_VALUE, size2:Int32 = 0) {
        super(tag);
        this.size1 = size1;
        this.size2 = size2;
    }

    override private function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        // XXX insufficient
        var str:String = s.readMultiByte(length, "US-ASCII");
        return str;
    }
}
