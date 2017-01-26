/**
 * KeyExchanges
 * 
 * An enumeration of key exchange methods defined by TLS
 * ( right now, only RSA is actually implemented )
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;

import haxe.Int32;

class KeyExchanges {
    public static inline var NULL = 0;
    public static inline var RSA = 1;
    public static inline var DH_DSS = 2;
    public static inline var DH_RSA = 3;
    public static inline var DHE_DSS = 4;
    public static inline var DHE_RSA = 5;
    public static inline var DH_anon = 6;

    public static function useRSA(p:Int32):Bool {
        return (p == RSA);
    }
}
