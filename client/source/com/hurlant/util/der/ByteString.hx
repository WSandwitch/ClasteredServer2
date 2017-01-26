/**
 * ByteString
 * 
 * An ASN1 type for a ByteString, represented with a ByteArray
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;

import haxe.Int32;
import com.hurlant.util.der.IAsn1Type;

import com.hurlant.util.ByteArray;
import com.hurlant.util.Hex;

class ByteString implements IAsn1Type {
    public var data:ByteArray;
    private var type:Int32;
    private var len:Int32;

    public function new(type:Int32 = 0x04, length:Int32 = 0x00) {
        this.data = new ByteArray();
        this.type = type;
        this.len = length;
    }

    public function getLength():Int32 {
        return len;
    }

    public function getType():Int32 {
        return type;
    }

    public function toDER():ByteArray {
        return DER.wrapDER(type, data);
    }

    public function toString():String {
        return DER.indent + "ByteString[" + type + "][" + len + "][" + Hex.fromArray(data) + "]";
    }
}
