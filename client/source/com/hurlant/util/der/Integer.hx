/**
 * Integer
 * 
 * An ASN1 type for an Integer, represented with a BigInteger
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;


import haxe.Int32;
import com.hurlant.math.BigInteger;
import com.hurlant.util.ByteArray;

class Integer extends BigInteger implements IAsn1Type {
    private var type:Int32;
    private var len:Int32;

    public function new(type:Int32, length:Int32, b:ByteArray) {
        this.type = type;
        this.len = length;
        super(b);
    }

    public function getLength():Int32 {
        return len;
    }

    public function getType():Int32 {
        return type;
    }

    override public function toString(radix:Float = 0):String {
        return DER.indent + "Integer[" + type + "][" + len + "][" + super.toString(16) + "]";
    }

    public function toDER():ByteArray {
        return null;
    }
}
