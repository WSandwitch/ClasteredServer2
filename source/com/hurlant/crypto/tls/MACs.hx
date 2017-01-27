/**
 * MACs
 * 
 * An enumeration of MACs implemented for TLS 1.0/SSL 3.0
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import haxe.Int32;
import com.hurlant.crypto.Crypto;
import com.hurlant.crypto.hash.HMAC;
import com.hurlant.crypto.hash.MAC;

class MACs {
    static public inline var NULL = 0;
    static public inline var MD5 = 1;
    static public inline var SHA1 = 2;

    static private var HASHES = ["", "md5", "sha1"];

    static public function getHashSize(hash:Int32):Int32 {
        return [0, 16, 20][hash];
    }

    static public function getPadSize(hash:Int32):Int32 {
        return [0, 48, 40][hash];
    }

    static public function getHMAC(hash:Int32):HMAC {
        if (hash == NULL) return null;
        return Crypto.getHMAC(HASHES[hash]);
    }

    static public function getMAC(hash:Int32):MAC {
        return Crypto.getMAC(HASHES[hash]);
    }
}
