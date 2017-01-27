/**
 * OID
 * 
 * A list of various ObjectIdentifiers.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;

class OID {
    public static inline var RSA_ENCRYPTION = "1.2.840.113549.1.1.1";
    public static inline var MD2_WITH_RSA_ENCRYPTION = "1.2.840.113549.1.1.2";
    public static inline var MD5_WITH_RSA_ENCRYPTION = "1.2.840.113549.1.1.4";
    public static inline var SHA1_WITH_RSA_ENCRYPTION = "1.2.840.113549.1.1.5";
    public static inline var SHA2_WITH_RSA_ENCRYPTION = "1.2.840.113549.1.1.11";
    public static inline var MD2_ALGORITHM = "1.2.840.113549.2.2";
    public static inline var MD5_ALGORITHM = "1.2.840.113549.2.5";
    public static inline var PKCS9_UNSTRUCTURED_NAME = "1.2.840.113549.1.9.2";
    public static inline var DSA = "1.2.840.10040.4.1";
    public static inline var DSA_WITH_SHA1 = "1.2.840.10040.4.3";
    public static inline var DH_PUBLIC_NUMBER = "1.2.840.10046.2.1";
    public static inline var SHA1_ALGORITHM = "1.3.14.3.2.26";
    public static inline var SHA2_ALGORITHM:String = "2.16.840.1.101.3.4.2.1";

    public static inline var COMMON_NAME = "2.5.4.3";
    public static inline var SURNAME = "2.5.4.4";
    public static inline var COUNTRY_NAME = "2.5.4.6";
    public static inline var LOCALITY_NAME = "2.5.4.7";
    public static inline var STATE_NAME = "2.5.4.8";
    public static inline var ORGANIZATION_NAME = "2.5.4.10";
    public static inline var ORG_UNIT_NAME = "2.5.4.11";
    public static inline var TITLE = "2.5.4.12";
}
