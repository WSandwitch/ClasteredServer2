/**
 * TLSConnectionState
 * 
 * This class encapsulates the read or write state of a TLS connection,
 * and implementes the encrypting and hashing of packets. 
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import haxe.Int32;
import com.hurlant.util.ByteArray;
import com.hurlant.crypto.hash.HMAC;
import com.hurlant.crypto.symmetric.ICipher;
import com.hurlant.crypto.symmetric.mode.IVMode;
import com.hurlant.util.ArrayUtil;

class TLSConnectionState implements IConnectionState {
    // compression state

    // cipher state
    private var bulkCipher:Int32;
    private var cipherType:Int32;
    private var CIPHER_key:ByteArray;
    private var CIPHER_IV:ByteArray;
    private var cipher:ICipher;
    private var ivmode:IVMode;

    // mac secret
    private var macAlgorithm:Int32;
    private var MAC_write_secret:ByteArray;
    private var hmac:HMAC;

    // sequence number. uint64
    private var seq_lo:Int32;
    private var seq_hi:Int32;

    public function new(
        bulkCipher:Int32 = 0, cipherType:Int32 = 0, macAlgorithm:Int32 = 0,
        mac:ByteArray = null, key:ByteArray = null, IV:ByteArray = null
    ) {
        this.bulkCipher = bulkCipher;
        this.cipherType = cipherType;
        this.macAlgorithm = macAlgorithm;
        this.MAC_write_secret = mac;
        this.hmac = MACs.getHMAC(macAlgorithm);
        this.CIPHER_key = key;
        this.CIPHER_IV = IV;
        this.cipher = BulkCiphers.getCipher(bulkCipher, key, 0x0301);
        if (Std.is(cipher, IVMode)) {
            this.ivmode = cast(cipher, IVMode);
            this.ivmode.IV = IV;
        }
    }

    public function decrypt(type:Int32, length:Int32, p:ByteArray):ByteArray {
        // decompression is a nop.

        if (cipherType == BulkCiphers.STREAM_CIPHER) {
            if (bulkCipher != BulkCiphers.NULL) cipher.decrypt(p);
        } else {
            // block cipher
            var nextIV = new ByteArray();
            nextIV.writeBytes(p, p.length - CIPHER_IV.length, CIPHER_IV.length);
            cipher.decrypt(p);
            CIPHER_IV = nextIV;
            ivmode.IV = nextIV;
        }

        if (macAlgorithm != MACs.NULL) {
            var data:ByteArray = new ByteArray();
            var len:Int32 = p.length - hmac.getHashSize();
            data.writeUnsignedInt(seq_hi);
            data.writeUnsignedInt(seq_lo);
            data.writeByte(type);
            data.writeShort(TLSSecurityParameters.PROTOCOL_VERSION);
            data.writeShort(len);
            if (len != 0) data.writeBytes(p, 0, len);
            var mac = hmac.compute(MAC_write_secret, data);
            // compare "mac" with the last X bytes of p.
            var mac_received:ByteArray = new ByteArray();
            mac_received.writeBytes(p, len, hmac.getHashSize());
            if (!ArrayUtil.equals(mac, mac_received)) throw new TLSError("Bad Mac Data", TLSError.bad_record_mac);
            p.length = len;
            p.position = 0;
        } // increment seq

        seq_lo++;
        if (seq_lo == 0) seq_hi++;
        return p;
    }

    public function encrypt(type:Int32, p:ByteArray):ByteArray {
        var mac:ByteArray = null;
        if (macAlgorithm != MACs.NULL) {
            var data:ByteArray = new ByteArray();
            data.writeUnsignedInt(seq_hi);
            data.writeUnsignedInt(seq_lo);
            data.writeByte(type);
            data.writeShort(TLSSecurityParameters.PROTOCOL_VERSION);
            data.writeShort(p.length);
            if (p.length != 0) data.writeBytes(p, 0, p.length);
            mac = hmac.compute(MAC_write_secret, data);
            p.position = p.length;
            p.writeBytes(mac);
        }
        p.position = 0;
        if (cipherType == BulkCiphers.STREAM_CIPHER) {
            // stream cipher
            if (bulkCipher != BulkCiphers.NULL) cipher.encrypt(p);
        } else {
            // block cipher
            cipher.encrypt(p);
            // adjust IV
            var nextIV = new ByteArray();
            nextIV.writeBytes(p, p.length - CIPHER_IV.length, CIPHER_IV.length);
            CIPHER_IV = nextIV;
            ivmode.IV = nextIV;
        } // increment seq

        seq_lo++;
        if (seq_lo == 0) seq_hi++ // compression is a nop.  ;

        return p;
    }
}
