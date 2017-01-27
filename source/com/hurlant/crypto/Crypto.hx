/**
 * Crypto
 * 
 * An abstraction layer to instanciate our crypto algorithms
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto;


import com.hurlant.crypto.encoding.binary.BinaryEncodings;
import com.hurlant.crypto.encoding.Charsets;
import com.hurlant.crypto.encoding.Charset;
import com.hurlant.crypto.encoding.binary.BinaryEncoding;
import com.hurlant.crypto.hash.RMD160;
import haxe.Int32;
import com.hurlant.crypto.hash.HMAC;
import com.hurlant.crypto.hash.MAC;
import com.hurlant.crypto.hash.IHash;
import com.hurlant.crypto.hash.MD2;
import com.hurlant.crypto.hash.MD5;
import com.hurlant.crypto.hash.SHA1;
import com.hurlant.crypto.hash.SHA224;
import com.hurlant.crypto.hash.SHA256;
import com.hurlant.crypto.prng.ARC4;
import com.hurlant.crypto.rsa.RSAKey;
import com.hurlant.crypto.symmetric.AESKey;
import com.hurlant.crypto.symmetric.BlowFishKey;
import com.hurlant.crypto.symmetric.mode.CBCMode;
import com.hurlant.crypto.symmetric.mode.CFB8Mode;
import com.hurlant.crypto.symmetric.mode.CFBMode;
import com.hurlant.crypto.symmetric.mode.CTRMode;
import com.hurlant.crypto.symmetric.DESKey;
import com.hurlant.crypto.symmetric.mode.ECBMode;
import com.hurlant.crypto.symmetric.ICipher;
import com.hurlant.crypto.symmetric.mode.IMode;
import com.hurlant.crypto.pad.IPad;
import com.hurlant.crypto.symmetric.ISymmetricKey;
import com.hurlant.crypto.symmetric.mode.IVMode;
import com.hurlant.crypto.pad.NullPad;
import com.hurlant.crypto.symmetric.mode.OFBMode;
import com.hurlant.crypto.pad.PKCS5;
import com.hurlant.crypto.symmetric.mode.SimpleIVMode;
import com.hurlant.crypto.symmetric.TripleDESKey;
import com.hurlant.crypto.symmetric.XTeaKey;

import com.hurlant.util.ByteArray;

/**
 * A class to make it easy to use the rest of the framework.
 * As a side-effect, using this class will cause most of the framework
 * to be linked into your application, which is not always what you want.
 *
 * If you want to optimize your download size, don't use this class.
 * (But feel free to read it to get ideas on how to get the algorithm you want.)
 */
class Crypto {
    /**
     * Things that should work, among others:
     *  "aes"
     *  "aes-128-ecb"
     *  "aes-128-cbc"
     *  "aes-128-cfb"
     *  "aes-128-cfb8"
     *  "aes-128-ofb"
     *  "aes-192-cfb"
     *  "aes-256-ofb"
     *  "blowfish-cbc"
     *  "des-ecb"
     *  "xtea"
     *  "xtea-ecb"
     *  "xtea-cbc"
     *  "xtea-cfb"
     *  "xtea-cfb8"
     *  "xtea-ofb"
     *  "rc4"
     *  "simple-aes-cbc"
     */
    public static function getCipher(name:String, key:ByteArray, pad:IPad = null):ICipher {
        // split name into an array.
        var keys:Array<Dynamic> = name.split("-");
        var _sw0_ = (keys[0]);

        switch (_sw0_) {
            case "simple", "aes", "aes128", "aes192", "aes256":
                switch (_sw0_) {
                    case "simple":
                        keys.shift();
                        name = keys.join("-");
                        var cipher = getCipher(name, key, pad);
                        if (Std.is(cipher, IVMode)) {
                            return new SimpleIVMode(cast(cipher, IVMode));
                        } else {
                            return cipher;
                        }
                    /*
                     * we support both "aes-128" and "aes128"
                     * Technically, you could use "aes192-128", but you'd
                     * only be hurting yourself.
                     */
                }
                keys.shift();
                if (key.length * 8 == keys[0]) {
                    // support for "aes-128-..." and such.
                    keys.shift();
                }
                return getMode(keys[0], new AESKey(key), pad);
            case "bf", "blowfish":
                keys.shift();
                return getMode(keys[0], new BlowFishKey(key), pad);
            case "des", "3des", "des3":

                switch (_sw0_) {
                    case "des":
                        keys.shift();
                        if (keys[0] != "ede" && keys[0] != "ede3") {
                            return getMode(keys[0], new DESKey(key), pad);
                        }
                        if (keys.length == 1) {
                            keys.push("ecb");
                        } // fall-through to triple des
                }
                keys.shift();
                return getMode(keys[0], new TripleDESKey(key), pad);
            case "xtea":
                keys.shift();
                return getMode(keys[0], new XTeaKey(key), pad);
            /*
             * Technically, you could say "rc4-128" or whatever,
             * but really, the length of the key is what counts here.
             */
            case "rc4":
                keys.shift();
                return new ARC4(key);
        }
        return null;
    }

    /**
     * Returns the size of a key for a given cipher identifier.
     */

    public static function getKeySize(name:String):Int32 {
        var keys = name.split("-");
        var _sw1_ = (keys[0]);

        return switch (_sw1_) {
            case "simple": getKeySize(keys.slice(1).join("-"));
            case "aes128": 16;
            case "aes192": 24;
            case "aes256": 32;
            case "aes": Std.int(Std.parseInt(keys[1]) / 8);
            case "bf", "blowfish": 16;
            case "xtea": 8;
            case "rc4": (Std.parseInt(keys[1]) > 0) ? Std.int(Std.parseInt(keys[1]) / 8) : 16;
            case "des", "3des", "des3":
                switch (_sw1_) {
                    case "des":
                        switch (keys[1]){
                            case "ede": 16;
                            case "ede3": 24;
                            default: 8;
                        }
                    default: 24;
                }
            default: 0;
        }
    }

    private static function getMode(name:String, alg:ISymmetricKey, padding:IPad = null):IMode {
        return switch (name) {
            case "ecb": new ECBMode(alg, padding);
            case "cfb": new CFBMode(alg, padding);
            case "cfb8": new CFB8Mode(alg, padding);
            case "ofb": new OFBMode(alg, padding);
            case "ctr": new CTRMode(alg, padding);
            case "cbc": new CBCMode(alg, padding);
            default: new CBCMode(alg, padding);
        }
    }

    /**
     * Things that should work:
     * "md5"
     * "sha"
     * "sha1"
     * "sha224"
     * "sha256"
     * "rmd160", "ripemd160"
     */
    public static function getHash(name:String):IHash {
        return switch (name.toLowerCase()) {
            case "md2": new MD2();
            case "md5": new MD5(); // let's hope you didn't mean sha-0
            case "sha", "sha1": new SHA1();
            case "sha224": new SHA224();
            case "sha256": new SHA256();
            case "rmd160", "ripemd160": new RMD160();
            default: null;
        }
    }

    /**
     * Things that should work:
     * "base16"
     * "base64"
     **/
    public static function getBinaryEncoding(name:String):BinaryEncoding {
        return BinaryEncodings.fromString(name);
    }

    /**
     * Things that should work:
     * "utf8"
     **/
    public static function getCharset(name:String):Charset {
        return Charsets.fromString(name);
    }

    /**
     * Things that should work:
     * "sha1"
     * "md5-64"
     * "hmac-md5-96"
     * "hmac-sha1-128"
     * "hmac-sha256-192"
     * etc.
     */

    public static function getHMAC(name:String):HMAC {
        var keys = name.split("-");
        if (keys[0] == "hmac") keys.shift();
        var bits = if (keys.length > 1) Std.parseInt(keys[1]) else 0;
        return new HMAC(getHash(keys[0]), bits);
    }


    public static function getMAC(name:String):MAC {
        var keys = name.split("-");
        if (keys[0] == "mac") keys.shift();
        var bits = if (keys.length > 1) Std.parseInt(keys[1]) else 0;
        return new MAC(getHash(keys[0]), bits);
    }

    public static function getPad(name:String):IPad {
        return switch (name) {
            case "null": new NullPad();
            case "pkcs5": new PKCS5();
            default: new PKCS5();
        }
    }

    // mostly useless.

    public static function getRSA(E:String, M:String):RSAKey {
        return RSAKey.parsePublicKey(M, E);
    }
}
