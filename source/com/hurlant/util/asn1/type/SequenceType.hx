package com.hurlant.util.asn1.type;

import haxe.Int32;
import com.hurlant.util.Error;

import com.hurlant.util.ByteArray;

class SequenceType extends ASN1Type {
    public var children:Array<SequenceTypeItem>;
    public var childType:ASN1Type;

    public function new(p:Array<SequenceTypeItem>) {
        super(ASN1Type.SEQUENCE);
        if (Std.is(p, Array)) {
            children = cast(p, Array<SequenceTypeItem>);
        } else {
            childType = cast(p, ASN1Type);
        }
    }

    override private function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        var p:Int32 = s.position;
        var left:Int32 = length;
        var val:Dynamic;
        var v:Dynamic; // v=individual children, val=entire sequence
        if (children != null) {
            // sequence
            val = { };
            for (i in 0...children.length) {
                for (name in Reflect.fields(children[i])) {
                    var pp:Int32 = s.position;
                    left = length - pp + p;
                    var child:ASN1Type = children[i][name];
                    v = child.fromDER(s, left);
                    if (v == null) {
                        if (!child.optional) {
                            s.position = p;
                            return null;
                        }
                    } else {
                        Reflect.setField(val, name, v);
                        if (child.extract) {
                            var bin:ByteArray = new ByteArray();
                            bin.writeBytes(s, pp, s.position - pp);
                            val[name + "_bin"] = bin;
                        }
                    }
                }
            }
            return val;
        } else {
            // sequenceOf
            val = [];
            while (left > 0) {
                v = childType.fromDER(s, left);
                if (v == null) throw new Error("couldn't parse DER stream.");
                val.push(v);
                left = length - s.position + p;
            }
            return val;
        }
    }
}
