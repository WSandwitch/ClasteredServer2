/**
 * X509Certificate
 * 
 * A representation for a X509 Certificate, with
 * methods to parse, verify and sign it.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.cert;

import haxe.Int32;
import com.hurlant.crypto.hash.SHA256;
import com.hurlant.crypto.cert.X509CertificateCollection;
import com.hurlant.util.Error;

import com.hurlant.crypto.hash.IHash;
import com.hurlant.crypto.hash.MD2;
import com.hurlant.crypto.hash.MD5;
import com.hurlant.crypto.hash.SHA1;
import com.hurlant.crypto.rsa.RSAKey;
import com.hurlant.util.ArrayUtil;
import com.hurlant.util.Base64;
import com.hurlant.util.der.ByteString;
import com.hurlant.util.der.DER;
import com.hurlant.util.der.OID;
import com.hurlant.util.der.ObjectIdentifier;
import com.hurlant.util.der.PEM;
import com.hurlant.util.der.Sequence;
import com.hurlant.util.der.Type;
import com.hurlant.util.der.Type2;

import com.hurlant.util.ByteArray;

class X509Certificate {
    private var _loaded:Bool;
    private var _param:Dynamic;
    //private var _obj:Object; // old ASN-1 parsing
    private var _obj2:Dynamic; // new ASN-1 library

    public function new(p:Dynamic) {
        _loaded = false;
        _param = p;
    }

    private function load():Void {
        if (_loaded) return;
        var p:Dynamic = _param;
        var b:ByteArray;
        if (Std.is(p, String)) {
            b = PEM.readCertIntoArray(cast(p, String));
        }
        else if (Std.is(p, ByteArray)) {
            b = p;
        }
        if (b != null) {
            var t1:Int32 = Math.round(haxe.Timer.stamp() * 1000);
            //_obj = DER.parse(b, Type.TLS_CERT);
            //trace("Type 1 method: "+(getTimer()-t1)+"ms");
            //b.position = 0;
            t1 = Math.round(haxe.Timer.stamp() * 1000);
            _obj2 = Type2.Certificate.fromDER(b, b.length);
            trace("Type 2 method: " + (Math.round(haxe.Timer.stamp() * 1000) - t1) + "ms");
            _loaded = true;
        }
        else {
            throw new Error("Invalid x509 Certificate parameter: " + p);
        }
    }

    public function isSigned(store:X509CertificateCollection, CAs:X509CertificateCollection, time:Date = null):Bool {
        load();
        // check timestamps first. cheapest.
        if (time == null) time = Date.now();
        var notBefore = getNotBefore();
        var notAfter = getNotAfter();
        if (time.getTime() < notBefore.getTime()) return false // cert isn't born yet.  ;
        if (time.getTime() > notAfter.getTime()) return false // check signature.    // cert died of old age.  ;

        var subject = getIssuerPrincipal();
        // try from CA first, since they're treated better.
        var parent = CAs.getCertificate(subject);
        var parentIsAuthoritative = false;
        if (parent == null) {
            parent = store.getCertificate(subject);
            if (parent == null) return false;
        } else {
            parentIsAuthoritative = true;
        }

        if (parent == this) { // pathological case. avoid infinite loop
            return false;
        }
        if (!(parentIsAuthoritative && parent.isSelfSigned(time)) && !parent.isSigned(store, CAs, time)) {
            return false;
        }
        var key:RSAKey = parent.getPublicKey();
        return verifyCertificate(key);
    }

    public function isSelfSigned(time:Date):Bool {
        load();

        var key:RSAKey = getPublicKey();
        return verifyCertificate(key);
    }

    private function verifyCertificate(key:RSAKey):Bool {
        var algo:String = getAlgorithmIdentifier();

        //var data:ByteArray = _obj.signedCertificate_bin;
        var hash = createHashFromAlgo(algo);
        var oid = getOIDFromObject(hash);
        if (hash == null) return false;
        var data = _obj2.toBeSigned_bin;
        var buf = new ByteArray();
        //key.verify(_obj.encrypted, buf, _obj.encrypted.length);
        key.verify(_obj2.signature, buf, _obj2.signature.length);
        buf.position = 0;
        data = hash.hash(data);
        var obj = DER.parse(buf, Type.RSA_SIGNATURE);
        return (Std.string(obj.algorithm.algorithmId) != oid) && (ArrayUtil.equals(obj.hash, data));
    }

    static private function createHashFromAlgo(algo:String):IHash {
        return switch (algo) {
            case OID.SHA1_WITH_RSA_ENCRYPTION: new SHA1();
            case OID.MD2_WITH_RSA_ENCRYPTION : new MD2() ;
            case OID.MD5_WITH_RSA_ENCRYPTION : new MD5() ;
            case OID.SHA2_WITH_RSA_ENCRYPTION: new SHA256();
            default: null;
        }
    }

    static private function getOIDFromObject(obj:Dynamic):String {
        if (obj == null) return null;
        if (Std.is(obj, SHA1)) return OID.SHA1_ALGORITHM;
        if (Std.is(obj, MD2)) return OID.MD2_ALGORITHM;
        if (Std.is(obj, MD5)) return OID.MD5_ALGORITHM;
        if (Std.is(obj, SHA256)) return OID.SHA2_ALGORITHM;
        return null;
    }

    /**
     * This isn't used anywhere so far.
     * It would become useful if we started to offer facilities
     * to generate and sign X509 certificates.
     *
     * @param key
     * @param algo
     * @return
     *
     */

    private function signCertificate(key:RSAKey, algo:String):ByteArray {
        var hash = createHashFromAlgo(algo);
        var oid = getOIDFromObject(hash);
        if (hash == null) return null;
        //var data:ByteArray = _obj.signedCertificate_bin;

        var data:ByteArray = _obj2.toBeSigned_bin;
        data = hash.hash(data);
        var seq1:Sequence = new Sequence();
        seq1[0] = new Sequence();
        seq1[0][0] = new ObjectIdentifier(0, 0, oid);
        seq1[0][1] = null;
        seq1[1] = new ByteString();
        seq1[1].writeBytes(data);
        data = seq1.toDER();
        var buf:ByteArray = new ByteArray();
        key.sign(data, buf, data.length);
        return buf;
    }

    public function getPublicKey():RSAKey {
        load();
        var pk:ByteArray = cast(_obj2.toBeSigned.subjectPublicKeyInfo.subjectPublicKey, ByteArray);
        pk.position = 0;
        var rsaKey:Dynamic = DER.parse(pk, [{name : "N"}, {name : "E"}]);
        return new RSAKey(rsaKey.N, rsaKey.E.valueOf());
    }

    /**
     * Returns a subject principal, as an opaque base64 string.
     * This is only used as a hash key for known certificates.
     *
     * Note that this assumes X509 DER-encoded certificates are uniquely encoded,
     * as we look for exact matches between Issuer and Subject fields.
     *
     */

    public function getSubjectPrincipal():String {
        load();
        //return Base64.encodeByteArray(_obj.signedCertificate.subject_bin);
        return Base64.encodeByteArray(_obj2.toBeSigned.subject_bin);
    }

    /**
     * Returns an issuer principal, as an opaque base64 string.
     * This is only used to quickly find matching parent certificates.
     *
     * Note that this assumes X509 DER-encoded certificates are uniquely encoded,
     * as we look for exact matches between Issuer and Subject fields.
     *
     */

    public function getIssuerPrincipal():String {
        load();
        //return Base64.encodeByteArray(_obj.signedCertificate.issuer_bin);
        return Base64.encodeByteArray(_obj2.toBeSigned.issuer_bin);
    }

    public function getAlgorithmIdentifier():String {
        //return _obj.algorithmIdentifier.algorithmId.toString();
        return Std.string(_obj2.algorithm.algorithm);
    }

    public function getNotBefore():Date {
        //return _obj.signedCertificate.validity.notBefore.date;
        return _obj2.toBeSigned.validity.notBefore.utcTime;
    }

    public function getNotAfter():Date {
        //return _obj.signedCertificate.validity.notAfter.date;
        return _obj2.toBeSigned.validity.notAfter.utcTime;
    }

    public function getCommonName():String {
        //var subject:Sequence = _obj.signedCertificate.subject;
        var subject:Array<Dynamic> = _obj2.toBeSigned.subject.sequence;
        for (i in 0...subject.length) {
            var e:Dynamic = subject[i][0];
            if (e.commonName) {
                // not sure I like this.
                var obj:Dynamic = e.commonName.value;
                var val:Dynamic;
                for (t in Reflect.fields(obj)) {
                    val = Reflect.field(obj, t);
                    break;
                }
                return val;
            }
        }
        // return (subject.findAttributeValue(OID.COMMON_NAME) as PrintableString).getString();

        return "hi";
    }
}
