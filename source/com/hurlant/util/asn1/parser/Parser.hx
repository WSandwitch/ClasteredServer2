package com.hurlant.util.asn1.parser;
import com.hurlant.util.asn1.type.SequenceTypeItem;
import haxe.Int32;
import com.hurlant.util.asn1.type.UTF8StringType;
import com.hurlant.util.asn1.type.UTCTimeType;
import com.hurlant.util.asn1.type.UniversalStringType;
import com.hurlant.util.asn1.type.TeletexStringType;
import com.hurlant.util.asn1.type.SetType;
import com.hurlant.util.asn1.type.SequenceType;
import com.hurlant.util.asn1.type.PrintableStringType;
import com.hurlant.util.asn1.type.OIDType;
import com.hurlant.util.asn1.type.OctetStringType;
import com.hurlant.util.asn1.type.NullType;
import com.hurlant.util.asn1.type.IntegerType;
import com.hurlant.util.asn1.type.IA5StringType;
import com.hurlant.util.asn1.type.GeneralizedTimeType;
import com.hurlant.util.asn1.type.ChoiceType;
import com.hurlant.util.asn1.type.BooleanType;
import com.hurlant.util.asn1.type.BMPStringType;
import com.hurlant.util.asn1.type.ASN1Type;
import com.hurlant.util.asn1.type.AnyType;
import com.hurlant.util.asn1.type.BitStringType;

class Parser {
    static public function any():ASN1Type {
        return new AnyType();
    }

    static public function bitString():ASN1Type {
        return new BitStringType();
    }

    static public function bmpString(size:Int32 = Int.MAX_VALUE, size2:Int32 = 0):BMPStringType {
        return new BMPStringType(size, size2);
    }

    static public function bool():ASN1Type {
        return new BooleanType();
    }

    static public function choice(p:Array<Dynamic>):ASN1Type {
        var a:Array<Dynamic> = [];
        for (i in 0...p.length) a[i] = p[i];
        return new ChoiceType(a);
    }

    static public function defaultValue(value:Dynamic, o:ASN1Type):ASN1Type {
        o = o.clone();
        o.defaultValue = value;
        return o;
    }

    static public function explicitTag(v:Int32, c:Int32, o:ASN1Type):ASN1Type {
        o = o.clone();
        o.explicitTag = v;
        o.explicitClass = c;
        return o;
    }

    static public function extract(o:ASN1Type):ASN1Type {
        o = o.clone();
        o.extract = true;
        return o;
    }

    static public function generalizedTime():GeneralizedTimeType {
        return new GeneralizedTimeType();
    }

    static public function ia5String(size:Int32 = Int.MAX_VALUE, size2:Int32 = 0):IA5StringType {
        return new IA5StringType(size, size2);
    }

    static public function implicitTag(v:Int32, c:Int32, o:ASN1Type):ASN1Type {
        o = o.clone();
        o.implicitTag = v;
        o.implicitClass = c;
        return o;
    }

    static public function integer():ASN1Type {
        return new IntegerType();
    }

    static public function nulll():NullType {
        return new NullType();
    }

    static public function octetString():ASN1Type {
        return new OctetStringType();
    }

    static public function oid():OIDType {
        var s:String = p.length > (0) ? p.join(".") : null;
        return new OIDType(s);
    }

    static public function optional(o:ASN1Type):ASN1Type {
        o = o.clone();
        o.optional = true;
        return o;
    }

    static public function printableString(size:Int32 = Int.MAX_VALUE, size2:Int32 = 0):ASN1Type {
        return new PrintableStringType(size, size2);
    }

    static public function sequence(p:Array<SequenceTypeItem>):ASN1Type {
        return new SequenceType(a.slice(0));
    }

    static public function sequenceOf(t:ASN1Type, min:Int32 = Int.MIN_VALUE, max:Int32 = Int.MAX_VALUE):ASN1Type {
        return new SequenceType(t);
    }

    static public function setOf(type:ASN1Type, min:Int32 = Int.MIN_VALUE, max:Int32 = Int.MAX_VALUE):ASN1Type {
        return new SetType(type);
    }

    static public function teletexString(size:Int32 = Int.MAX_VALUE, size2:Int32 = 0):ASN1Type {
        return new TeletexStringType(size, size2);
    }

    static public function universalString(size:Int32 = Int.MAX_VALUE, size2:Int32 = 0):UniversalStringType {
        return new UniversalStringType(size, size2);
    }

    static public function utcTime():UTCTimeType {
        return new UTCTimeType();
    }

    static public function utf8String(size : Int32 = Int.MAX_VALUE, size2 : Int32 = 0) : UTF8StringType{
        return new UTF8StringType(size, size2);
    }
}
