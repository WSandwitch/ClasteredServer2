/**
 * Type
 * 
 * A few Asn-1 structures
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;

import com.hurlant.util.Hex;
import com.hurlant.util.asn1.type.ASN1Type;

class Type {
    private var test:ASN1Type = Type2.Certificate;

    public static var TLS_CERT:Array<TlsCert> = [
        {
            name : "signedCertificate",
            extract : true,
            value : [
                {
                    name : "versionHolder",
                    optional : true,
                    value : [
                        { name : "version" }
                    ],
                    defaultValue : new Sequence(0, 0).pushStr("version", new Integer(2, 1, Hex.toArray("00")))
                },
                { name : "serialNumber" },
                {
                    name : "signature",
                    value : [ { name : "algorithmId" } ]
                },
                {
                    name : "issuer",
                    extract : true,
                    value : [
                        { name : "type" },
                        { name : "value" }
                    ]
                },
                {
                    name : "validity",
                    value : [
                        { name : "notBefore" },
                        { name : "notAfter" }
                    ]
                },
                {
                    name : "subject",
                    extract : true,
                    value : []
                },
                {
                    name : "subjectPublicKeyInfo",
                    value : [
                        {
                            name : "algorithm",
                            value : [ { name : "algorithmId" }]
                        },
                        { name : "subjectPublicKey" }
                    ]
                },
                {
                    name : "extensions",
                    value : []
                }
            ]
        },
        {
            name : "algorithmIdentifier",
            value : [
                { name : "algorithmId" }
            ]
        },
        {
            name : "encrypted",
            value : null
        }
    ];

    public static var CERTIFICATE:Array<Certificate> = [
        {
            name : "tbsCertificate",
            value : [
                {
                    name : "tag0",
                    value : [ { name : "version" }]
                },
                { name : "serialNumber" },
                { name : "signature" },
                {
                    name : "issuer",
                    value : [
                        { name : "type" },
                        { name : "value" }
                    ]
                },
                {
                    name : "validity",
                    value : [
                        { name : "notBefore" },
                        { name : "notAfter" }
                    ]
                },
                { name : "subject" },
                {
                    name : "subjectPublicKeyInfo",
                    value : [
                        { name : "algorithm" },
                        { name : "subjectPublicKey" }
                    ]
                },
                { name : "issuerUniqueID" },
                { name : "subjectUniqueID" },
                { name : "extensions" }
            ]

        },
        { name : "signatureAlgorithm" },
        { name : "signatureValue" }
    ];

    public static var RSA_PUBLIC_KEY:Array<RsaPublicKey> = [
        { name : "modulus" },
        { name : "publicExponent" }
    ];

    public static var RSA_SIGNATURE:Array<RsaSignature> = [
        { name : "algorithm", value : [ { name : "algorithmId" }] },
        { name : "hash" }
    ];
}


typedef TlsCertTypedef = {
    var name:String;
    var extract:Bool;
    var value:Dynamic;
}

typedef CertificateTypedef = {
    var name:String;
    var value:Dynamic;
}

typedef RsaPublicKeyTypedef = {
    var name:String;
}

typedef RsaSignatureTypedef = {
    var name:String;
    var value:Dynamic;
}
