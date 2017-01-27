/**
 * TLSError
 * 
 * A error that can be thrown when something wrong happens in the TLS protocol.
 * This is handled in TLSEngine by generating a TLS ALERT as appropriate.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;

import haxe.Int32;
import com.hurlant.util.Error;

class TLSError extends Error {
    public static inline var close_notify = 0;
    public static inline var unexpected_message = 10;
    public static inline var bad_record_mac = 20;
    public static inline var decryption_failed = 21;
    public static inline var record_overflow = 22;
    public static inline var decompression_failure = 30;
    public static inline var handshake_failure = 40;
    public static inline var bad_certificate = 42;
    public static inline var unsupported_certificate = 43;
    public static inline var certificate_revoked = 44;
    public static inline var certificate_expired = 45;
    public static inline var certificate_unknown = 46;
    public static inline var illegal_parameter = 47;
    public static inline var unknown_ca = 48;
    public static inline var access_denied = 49;
    public static inline var decode_error = 50;
    public static inline var decrypt_error = 51;
    public static inline var protocol_version = 70;
    public static inline var insufficient_security = 71;
    public static inline var internal_error = 80;
    public static inline var user_canceled = 90;
    public static inline var no_renegotiation = 100;

    public function new(message:String, id:Int32) {
        //super(message, id);
        super(message);
    }
}
