package com.hurlant.util.asn1.type;

import haxe.Int32;
import com.hurlant.util.asn1.type.ASN1Type;
import com.hurlant.util.Error;

import com.hurlant.util.ByteArray;

class AnyType extends ASN1Type {
    public function new() {
        super(ASN1Type.ANY);
        throw new Error("the ASN-1 ANY type is NOT IMPLEMENTED");
    }

    /**
     * hmm. this is similar to what we used to do.
     * Typeless parsing. fun.
     * And yet, this is now somewhat harder to do. :(
     *
     * @param s
     * @param length
     * @return
     *
     */
    override private function fromDERContent(s:ByteArray, length:Int32):Dynamic {
        // hmmm I have the universal type found in parsedTag
        // but then what?
        // do I need a factory that returns a type for it?
        // blah. pain in the butt.
        trace("ANY parsing not implemented :(");
        switch (parsedTag)
        {
            case NULL:return "NULL";
        }
        return null;
    }
}
