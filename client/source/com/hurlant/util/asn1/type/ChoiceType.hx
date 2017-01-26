package com.hurlant.util.asn1.type;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class ChoiceType extends ASN1Type {
    public var choices:Array<Dynamic>;

    public function new(p:Array<Dynamic> = null) {
        super(ASN1Type.CHOICE);
        choices = p;
    }

    override public function fromDER(s:ByteArray, size:Int32):Dynamic {
        // just loop through each choice until one of them is non-null
        // XXX this will fail horribly if one of the choices has a default value.
        // I kinda hope that's forbidden by common sense somewhere.
        for (i in 0...choices.length) {
            var c:Dynamic = choices[i];
            for (name in Reflect.fields(c)) {
                var choice:ASN1Type = Reflect.field(c, name);
                var v:Dynamic = choice.fromDER(s, size);
                if (v != null) {
                    var val:Dynamic = { };
                    Reflect.setField(val, name, v);
                    return val;
                }
            }
        }
        return null;
    }
}
