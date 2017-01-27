/**
 * Sequence
 * 
 * An ASN1 type for a Sequence, implemented as an Array
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class Sequence implements IAsn1Type {
    public var data:Array<Dynamic>;
    private var strData:Map<String, Dynamic>;
    private var type:Int;
    private var len:Int;

    public function new(type:Int = 0x30, length:Int = 0x00) {
        this.strData = new Map<String, Dynamic>();
        this.data = [];
        this.type = type;
        this.len = length;
    }

    public function set(index:Int32, value:Dynamic):Dynamic {
        return data[index] = value;
    }

    public function get(index:Int32):Dynamic {
        return data[index];
    }

    public function pushStr(name:String, value:Dynamic):Sequence {
        this.push(value);
        this.setStr(name, value);
        return this;
    }

    public function setStr(index:String, value:Dynamic):Dynamic {
        return strData[index] = value;
    }

    public function getStr(index:String):Dynamic {
        return strData[index];
    }

    public function push(value:Dynamic) {
        return this.data.push(value);
    }

    public function getLength():Int {
        return len;
    }

    public function getType():Int {
        return type;
    }

    public function toDER():ByteArray {
        var tmp:ByteArray = new ByteArray();
        for (i in 0...data.length) {
            var e:IAsn1Type = data[i];
            if (e == null) { // XXX Arguably, I could have a der.Null class instead
                tmp.writeByte(0x05);
                tmp.writeByte(0x00);
            }
            else {
                tmp.writeBytes(e.toDER());
            }
        }
        return DER.wrapDER(type, tmp);
    }

    public function toString():String {
        var s:String = DER.indent;
        DER.indent += "    ";
        var t:String = "";
        for (i in 0...data.length) {
            if (data[i] == null) continue;
            var found:Bool = false;
            for (key in Reflect.fields(data)) {
                if ((Std.string(i) != key) && data[i] == Reflect.field(data, key)) {
                    t += key + ": " + data[i] + "\n";
                    found = true;
                    break;
                }
            }
            if (!found) t += data[i] + "\n";
        } //			var t:String = join("\n");

        DER.indent = s;
        return DER.indent + "Sequence[" + type + "][" + len + "][\n" + t + "\n" + s + "]";
    }

    /////////

    public function findAttributeValue(oid:String):IAsn1Type {
        for (set in data) {
            if (Std.is(set, Set)) {
                var child = cast(set, Set).get(0);
                if (Std.is(child, Sequence)) {
                    var tmp = cast(child, Sequence).get(0);
                    if (Std.is(tmp, ObjectIdentifier)) {
                        var id = cast(tmp, ObjectIdentifier);
                        if (id.toString() == oid) {
                            return cast(child.get(1), IAsn1Type);
                        }
                    }
                }
            }
        }
        return null;
    }
}
