/**
 * PrintableString
 * 
 * An ASN1 type for a PrintableString, held within a String
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class PrintableString implements IAsn1Type {
    private var type:Int32;
    private var len:Int32;
    private var str:String;

    public function new(type:Int32, length:Int32) {
        this.type = type;
        this.len = length;
    }

    public function getLength():Int32 {
        return len;
    }

    public function getType():Int32 {
        return type;
    }

    public function setString(s:String):PrintableString {
        str = s;
        return this;
    }

    public function getString():String {
        return str;
    }

    public function toString():String {
        return DER.indent + str;
    }

    public function toDER():ByteArray {
        return null;
    }
}
