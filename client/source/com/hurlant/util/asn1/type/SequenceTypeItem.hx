package com.hurlant.util.asn1.type;

import com.hurlant.util.der.IAsn1Type;

class SequenceTypeItem {
    public var key:String;
    public var value:IAsn1Type;

    public function new(key:String, value:IAsn1Type) {
        this.key = key;
        this.value = value;
    }
}