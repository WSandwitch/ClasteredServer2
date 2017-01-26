package com.hurlant.util.der;


import haxe.Int32;
import com.hurlant.util.asn1.parser.Parser;
import com.hurlant.util.asn1.type.ASN1Type;
import com.hurlant.util.asn1.type.OIDType;

class Type2 {
    //  specifications of Upper Bounds
    //  shall be regarded as mandatory
    //  from Annex B of ITU-T X.411
    //  Reference Definition of MTS Parameter Upper Bounds

    //      Upper Bounds
    public static inline var ub_name = 32768;
    public static inline var ub_common_name = 64;
    public static inline var ub_locality_name = 128;
    public static inline var ub_state_name = 128;
    public static inline var ub_organization_name = 64;
    public static inline var ub_organizational_unit_name = 64;
    public static inline var ub_title = 64;
    public static inline var ub_match = 128;

    public static inline var ub_emailaddress_length = 128;

    public static inline var ub_common_name_length = 64;
    public static inline var ub_country_name_alpha_length = 2;
    public static inline var ub_country_name_numeric_length = 3;
    public static inline var ub_domain_defined_attributes = 4;
    public static inline var ub_domain_defined_attribute_type_length = 8;
    public static inline var ub_domain_defined_attribute_value_length = 128;
    public static inline var ub_domain_name_length = 16;
    public static inline var ub_extension_attributes = 256;
    public static inline var ub_e163_4_number_length = 15;
    public static inline var ub_e163_4_sub_address_length = 40;
    public static inline var ub_generation_qualifier_length = 3;
    public static inline var ub_given_name_length = 16;
    public static inline var ub_initials_length = 5;
    public static inline var ub_integer_options = 256;
    public static inline var ub_numeric_user_id_length = 32;
    public static inline var ub_organization_name_length = 64;
    public static inline var ub_organizational_unit_name_length = 32;
    public static inline var ub_organizational_units = 4;
    public static inline var ub_pds_name_length = 16;
    public static inline var ub_pds_parameter_length = 30;
    public static inline var ub_pds_physical_address_lines = 6;
    public static inline var ub_postal_code_length = 16;
    public static inline var ub_surname_length = 40;
    public static inline var ub_terminal_id_length = 24;
    public static inline var ub_unformatted_address_length = 180;
    public static inline var ub_x121_address_length = 16;
    public static inline var ub_pkcs9_string = 255; // see ftp://ftp.rsasecurity.com/pub/pkcs/pkcs-9-v2/pkcs-9.pdf, ASN.1 module, pkcs-9-ub-pkcs9String

    // Note - upper bounds on TeletexString are measured in characters.
    // A significantly greater number of octets will be required to hold
    // such a value.  As a minimum, 16 octets, or twice the specified upper
    // bound, whichever is the larger, should be allowed.
    // XXX ASN-1 was clearly invented to scare children.

    // yay for implicit upper bounds being explicitely specified.
    public static var MAX = Int.MAX_VALUE;

    // PKIX specific OIDs
    public static inline var iso:String = "1";
    public static inline var identified_organization:String = "3";
    public static inline var dod:String = "6";
    public static inline var internet:String = "1";
    public static inline var security:String = "5";
    public static inline var mechanisms:String = "5";
    public static inline var pkix:String = "7";
    public static var id_pkix:OIDType = Parser.oid(iso, identified_organization, dod, internet, security, mechanisms, pkix);

    // PKIX arcs
    // arc for private certificate extensions
    public static var id_pe:OIDType = Parser.oid(id_pkix, 1);
    // arc for policy qualifier types
    public static var id_qt:OIDType = Parser.oid(id_pkix, 2);
    // arc for extended key purpose OIDS
    public static var id_kp:OIDType = Parser.oid(id_pkix, 3);
    // arc for access descriptors
    public static var id_ad:OIDType = Parser.oid(id_pkix, 48);

    // policyQualifierIds for Internet policy qualifiers
    //		OID for CPS qualifier
    public static var id_qt_cps:OIDType = Parser.oid(id_qt, 1);
    //		OID for user notice qualifier
    public static var id_qt_unotice:OIDType = Parser.oid(id_qt, 2);

    public static var pkcs_9:OIDType = Parser.oid(iso, member_body, us, rsadsi, pkcs, 9);
    public static var emailAddress:OIDType = Parser.oid(pkcs_9, 1);
    // oh look, an Unstructured Name ... Joy..YAY for VMWare. BP
    public static var pkcs9_unstructuredName:OIDType = Parser.oid(pkcs_9, 2);

    // object identifiers for Name type and directory attribute support

    // Object identifier assignments
    public static inline var joint_iso_ccitt = "2";
    public static inline var ds = "5";

    public static var id_at:OIDType = Parser.oid(joint_iso_ccitt, ds, 4);
    // Attributes
    public static var id_at_commonName:OIDType = Parser.oid(id_at, 3);
    public static var id_at_surname:OIDType = Parser.oid(id_at, 4);
    public static var id_at_serialNumber:OIDType = Parser.oid(id_at, 5);
    public static var id_at_countryName:OIDType = Parser.oid(id_at, 6);
    public static var id_at_localityName:OIDType = Parser.oid(id_at, 7);
    public static var id_at_stateOrProvinceName:OIDType = Parser.oid(id_at, 8);
    public static var id_at_organizationName:OIDType = Parser.oid(id_at, 10);
    public static var id_at_organizationalUnitName:OIDType = Parser.oid(id_at, 11);
    public static var id_at_title:OIDType = Parser.oid(id_at, 12);
    public static var id_at_name:OIDType = Parser.oid(id_at, 41);
    public static var id_at_givenName:OIDType = Parser.oid(id_at, 42);
    public static var id_at_initials:OIDType = Parser.oid(id_at, 43);
    public static var id_at_generationQualifier:OIDType = Parser.oid(id_at, 44);
    public static var id_at_dnQualifier:OIDType = Parser.oid(id_at, 46);

    // algorithm identifiers and parameter structures
    public static inline var member_body = "2";
    public static inline var us = "840";
    public static inline var rsadsi = "113549";
    public static inline var pkcs = "1";
    public static inline var x9_57 = "10040";
    public static inline var x9algorithm = "4";
    public static inline var ansi_x942 = "10046";
    public static inline var number_type = "2";

    public static var pkcs_1:OIDType = Parser.oid(iso, member_body, us, rsadsi, pkcs, 1);

    public static var rsaEncryption:OIDType = Parser.oid(pkcs_1, 1);
    public static var md2WithRSAEncryption:OIDType = Parser.oid(pkcs_1, 2);
    public static var md5WithRSAEncryption:OIDType = Parser.oid(pkcs_1, 4);
    public static var sha1WithRSAEncryption:OIDType = Parser.oid(pkcs_1, 5);
    public static var id_dsa_with_sha1:OIDType = Parser.oid(iso, member_body, us, x9_57, x9algorithm, 3);
    public static var Dss_Sig_Value:ASN1Type = Parser.sequence({ r : Parser.integer() }, { s : Parser.integer() });
    public static var dhpublicnumber:OIDType = Parser.oid(iso, member_body, us, ansi_x942, number_type, 1);
    public static var ValidationParms:ASN1Type = Parser.sequence([{ seed : Parser.bitString() }, { pgenCounter : Parser.integer() }]);
    public static var DomainParameters:ASN1Type = Parser.sequence([
        //new SequenceTypeItem("p", Parser.integer()), // odd prime, p=jq +1
        { p : Parser.integer() }, // odd prime, p=jq +1
        { g : Parser.integer() }, // generator, g
        { q : Parser.integer() }, // factor of p-1
        { j : Parser.optional(Parser.integer()) }, // subgroup factor, j>= 2
        { validationParms : Parser.optional(ValidationParms) }
    ]);
    public static var id_dsa:OIDType = Parser.oid(iso, member_body, us, x9_57, x9algorithm, 1);
    public static var Dss_Parms:ASN1Type = Parser.sequence([
        { p : Parser.integer() },
        { q : Parser.integer() },
        { g : Parser.integer() }
    ]);

    // attribute data type
    public static var Attribute = function(Type:ASN1Type, id:OIDType):ASN1Type {
        return Parser.sequence(
            { type : id },
            { values : Parser.setOf(Type, 1, MAX) }
        );
    };

    public static var Version:ASN1Type = Parser.integer();

    public static var Extension:ASN1Type = Parser.sequence([
        { extnId : Parser.oid() },
        { critical : Parser.defaultValue(false, Bool()) },
        { extnValue : Parser.octetString() } // not quite enough. see line 5155
    ]);
    public static var Extensions:ASN1Type = Parser.sequenceOf(Extension, 1, MAX);
    public static var UniqueIdentifier:ASN1Type = Parser.bitString();
    public static var CertificateSerialNumber:ASN1Type = Parser.integer();

    // Directory string type, used extensively in Name types
    public static var directoryString = function(maxSize:Int32):ASN1Type {
        return Parser.choice([
            //{ teletexString : Parser.teletexString(1, maxSize) },
            { printableString : Parser.printableString(1, maxSize) },
            { utf8String: Parser.utf8String(1,maxSize) },
            { universalString : Parser.universalString(1, maxSize) },
            //{ bmpString : Parser.bmpString(1, maxSize) },
            //{ utf8String : Parser.utf8String(1, maxSize) }
            { teletexString: Parser.teletexString(1,maxSize) },
            { bmpString: Parser.bmpString(1,maxSize) },
            //{ ia5String: Parser.ia5String(1,maxSize) } // @TODO: Check this!
        ]);
    };

    // PKCS9 string value, handled for VMWare cases (and anyone with pkcs unstructured strings
    public static var pkcs9string = function(maxSize:Int32):ASN1Type {
        return Parser.choice([
            { utf8String : Parser.utf8String(1, maxSize) },
            { directoryString : Parser.directoryString(maxSize) }
        ]);
    };

    public static var AttributeTypeAndValue:ASN1Type = Parser.choice(
        { name: Parser.sequence([
            { type: id_at_name },
            { value: directoryString(ub_name) }
        ])},
        { commonName: Parser.sequence([
            { type: id_at_commonName },
            { value: directoryString(ub_common_name) }
        ])},
        { surname: Parser.sequence([
            { type: id_at_surname },
            { value: directoryString(ub_name) }
        ])},
        { givenName: Parser.sequence([
            { type: id_at_givenName },
            { value: directoryString(ub_name) }
        ])},
        { initials: Parser.sequence([
            { type: id_at_initials },
            { value: directoryString(ub_name) }
        ])},
        { generationQualifier: Parser.sequence([
            { type: id_at_generationQualifier },
            { value: directoryString(ub_name) }
        ])},
        { dnQualifier: Parser.sequence([
            { type: id_at_dnQualifier },
            { value: printableString() }
        ])},
        { countryName: Parser.sequence([
            { type: id_at_countryName },
            { value: printableString(2) } // IS 3166 codes only
        ])},
        { localityName: Parser.sequence([
            { type: id_at_localityName },
            { value: directoryString(ub_locality_name) }
        ])},
        { stateOrProvinceName: Parser.sequence([
            { type: id_at_stateOrProvinceName },
            { value: directoryString(ub_state_name) }
        ])},
        { organizationName: Parser.sequence([
            { type: id_at_organizationName },
            { value: directoryString(ub_organization_name) }
        ])},
        { organizationalUnitName: Parser.sequence([
            { type: id_at_organizationalUnitName },
            { value: directoryString(ub_organizational_unit_name) }
        ])},
        { title: Parser.sequence([
            { type: id_at_title },
            { value: directoryString(ub_title) }
        ])},
            // Legacy attributes
        { pkcs9email: Parser.sequence([
            { type: emailAddress },
            { value: Parser.ia5String(ub_emailaddress_length) }
        ])},
        { pkcs9UnstructuredName: Parser.sequence([
            { type : pkcs9_unstructuredName },
            { value: pkcs9string(ub_pkcs9_string) }
        ])}
    );

    public static var RelativeDistinguishedName:ASN1Type = Parser.setOf(AttributeTypeAndValue, 1, MAX);
    public static var RDNSequence:ASN1Type = Parser.sequenceOf(RelativeDistinguishedName);
    public static var Name:ASN1Type = Parser.choice([{
        sequence : RDNSequence
    }]);

    public static var Time = Parser.choice([
        { utcTime : Parser.utcTime() },
        { generalTime : Parser.generalizedTime() }
    ]);
    public static var Validity:ASN1Type = Parser.sequence([
        { notBefore : Time },
        { notAfter : Time }
    ]);
    // Definition of AlgorithmIdentifier
    public static var AlgorithmIdentifier:ASN1Type = Parser.sequence(
        { algorithm: Parser.oid() },
            // { parameters: optional(any()) } // XXX any not implemented (line 5281)
        { parameters: Parser.optional(Parser.choice([
            { none: Parser.nulll() },
            { dss_parms: Dss_Parms },
            { domainParameters: DomainParameters }
        ]))
        }
    );

    public static var SubjectPublicKeyInfo:ASN1Type = Parser.sequence([
        { algorithm : AlgorithmIdentifier },
        { subjectPublicKey : Parser.bitString() }
    ]);

    // Parameterized Type SIGNED
    public static var signed = function(o:ASN1Type):ASN1Type {
        return Parser.sequence([
            { toBeSigned : Parser.extract(o) },
            { algorithm : Parser.AlgorithmIdentifier },
            { signature : Parser.bitString() }
        ]);
    };

    // Public Key Certificate
    public static var Certificate = signed(Parser.sequence([
        { version : Parser.explicitTag(0, ASN1Type.CONTEXT, Parser.defaultValue(0, Version)) },
        { serialNumber : CertificateSerialNumber },
        { signature : AlgorithmIdentifier },
        { issuer : Parser.extract(Name) },
        { validity : Validity },
        { subject : Parser.extract(Name) },
        { subjectPublicKeyInfo : SubjectPublicKeyInfo },
        { issuerUniqueIdentifier : Parser.implicitTag(1, ASN1Type.CONTEXT, optional(UniqueIdentifier)) },
        { subjectUniqueIdentifier : Parser.implicitTag(2, ASN1Type.CONTEXT, optional(UniqueIdentifier)) },
        { extensions : Parser.explicitTag(3, ASN1Type.CONTEXT, Parser.optional(Extensions)) }
    ]));

}

