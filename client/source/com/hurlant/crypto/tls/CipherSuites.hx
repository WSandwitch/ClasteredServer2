/**
 * CipherSuites
 * 
 * An enumeration of cipher-suites available for TLS to use, along with
 * their properties, and some convenience methods
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;

import haxe.Int32;
import com.hurlant.util.Error;

class CipherSuites {
    // only the lines marked "ok" are currently implemented.

    // rfc 2246

    public static inline var TLS_NULL_WITH_NULL_NULL = 0x0000; // ok  
    public static inline var TLS_RSA_WITH_NULL_MD5 = 0x0001; // ok  
    public static inline var TLS_RSA_WITH_NULL_SHA = 0x0002; // ok  
    public static inline var TLS_RSA_WITH_RC4_128_MD5 = 0x0004; // ok  
    public static inline var TLS_RSA_WITH_RC4_128_SHA = 0x0005; // ok  
    public static inline var TLS_RSA_WITH_IDEA_CBC_SHA = 0x0007;
    public static inline var TLS_RSA_WITH_DES_CBC_SHA = 0x0009; // ok  
    public static inline var TLS_RSA_WITH_3DES_EDE_CBC_SHA = 0x000A; // ok  

    public static inline var TLS_DH_DSS_WITH_DES_CBC_SHA = 0x000C;
    public static inline var TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA = 0x000D;
    public static inline var TLS_DH_RSA_WITH_DES_CBC_SHA = 0x000F;
    public static inline var TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA = 0x0010;
    public static inline var TLS_DHE_DSS_WITH_DES_CBC_SHA = 0x0012;
    public static inline var TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA = 0x0013;
    public static inline var TLS_DHE_RSA_WITH_DES_CBC_SHA = 0x0015;
    public static inline var TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA = 0x0016;

    public static inline var TLS_DH_anon_WITH_RC4_128_MD5 = 0x0018;
    public static inline var TLS_DH_anon_WITH_DES_CBC_SHA = 0x001A;
    public static inline var TLS_DH_anon_WITH_3DES_EDE_CBC_SHA = 0x001B;

    // rfc3268

    public static inline var TLS_RSA_WITH_AES_128_CBC_SHA = 0x002F; // ok  
    public static inline var TLS_DH_DSS_WITH_AES_128_CBC_SHA = 0x0030;
    public static inline var TLS_DH_RSA_WITH_AES_128_CBC_SHA = 0x0031;
    public static inline var TLS_DHE_DSS_WITH_AES_128_CBC_SHA = 0x0032;
    public static inline var TLS_DHE_RSA_WITH_AES_128_CBC_SHA = 0x0033;
    public static inline var TLS_DH_anon_WITH_AES_128_CBC_SHA = 0x0034;

    public static inline var TLS_RSA_WITH_AES_256_CBC_SHA = 0x0035; // ok  
    public static inline var TLS_DH_DSS_WITH_AES_256_CBC_SHA = 0x0036;
    public static inline var TLS_DH_RSA_WITH_AES_256_CBC_SHA = 0x0037;
    public static inline var TLS_DHE_DSS_WITH_AES_256_CBC_SHA = 0x0038;
    public static inline var TLS_DHE_RSA_WITH_AES_256_CBC_SHA = 0x0039;
    public static inline var TLS_DH_anon_WITH_AES_256_CBC_SHA = 0x003A;

    private static var _props:Array<CipherSuites>;

    private static function initOnce():Void {
        if (_props != null) return;
        _props = [];
        _props[TLS_NULL_WITH_NULL_NULL] = new CipherSuites(BulkCiphers.NULL, MACs.NULL, KeyExchanges.NULL);
        _props[TLS_RSA_WITH_NULL_MD5] = new CipherSuites(BulkCiphers.NULL, MACs.MD5, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_NULL_SHA] = new CipherSuites(BulkCiphers.NULL, MACs.SHA1, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_RC4_128_MD5] = new CipherSuites(BulkCiphers.RC4_128, MACs.MD5, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_RC4_128_SHA] = new CipherSuites(BulkCiphers.RC4_128, MACs.SHA1, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_DES_CBC_SHA] = new CipherSuites(BulkCiphers.DES_CBC, MACs.SHA1, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_3DES_EDE_CBC_SHA] = new CipherSuites(BulkCiphers.DES3_EDE_CBC, MACs.SHA1, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_AES_128_CBC_SHA] = new CipherSuites(BulkCiphers.AES_128, MACs.SHA1, KeyExchanges.RSA);
        _props[TLS_RSA_WITH_AES_256_CBC_SHA] = new CipherSuites(BulkCiphers.AES_256, MACs.SHA1, KeyExchanges.RSA);
    }

    private static function getProp(cipher:Int32):CipherSuites {
        var p = _props[cipher];
        if (p == null) throw new Error("Unknown cipher $cipher");
        return p;
    }

    public static function getBulkCipher(cipher:Int32):Int32 {
        return getProp(cipher).cipher;
    }

    public static function getMac(cipher:Int32):Int32 {
        return getProp(cipher).hash;
    }

    public static function getKeyExchange(cipher:Int32):Int32 {
        return getProp(cipher).key;
    }

    public static function getDefaultSuites():Array<Int32> {
        // a list of acceptable ciphers, sorted by preference.
        return [
            TLS_RSA_WITH_AES_256_CBC_SHA,
            TLS_RSA_WITH_3DES_EDE_CBC_SHA,
            TLS_RSA_WITH_AES_128_CBC_SHA,
            TLS_RSA_WITH_RC4_128_SHA,
            TLS_RSA_WITH_RC4_128_MD5,
            TLS_RSA_WITH_DES_CBC_SHA
        ];
    }

    public var cipher:Int32;
    public var hash:Int32;
    public var key:Int32;

    public function new(cipher:Int32, hash:Int32, key:Int32) {
        initOnce();
        this.cipher = cipher;
        this.hash = hash;
        this.key = key;
    }
}

