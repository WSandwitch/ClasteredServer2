/**
 * Set
 * 
 * An ASN1 type for an Set, that extends a Sequence
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;

import haxe.Int32;
class Set extends Sequence {
    public function new(type:Int32 = 0x31, length:Int32 = 0x00) {
        super(type, length);
    }

    override public function toString():String {
        var s:String = DER.indent;
        DER.indent += "    ";
        var t:String = this.data.join("\n");
        DER.indent = s;
        return DER.indent + "Set[" + type + "][" + len + "][\n" + t + "\n" + s + "]";
    }
}
