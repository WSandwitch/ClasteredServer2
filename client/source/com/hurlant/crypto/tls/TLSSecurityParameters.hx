/**
 * TLSSecurityParameters
 * 
 * This class encapsulates all the security parameters that get negotiated
 * during the TLS handshake. It also holds all the key derivation methods.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Patched by Bobby Parker (sh0rtwave[at]gmail.com)
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import haxe.Int32;
import com.hurlant.crypto.hash.MD5;
import com.hurlant.crypto.hash.SHA1;
import com.hurlant.crypto.prng.TLSPRF;
import com.hurlant.util.Hex;

import com.hurlant.util.ByteArray;
import com.hurlant.crypto.rsa.RSAKey;

class TLSSecurityParameters implements ISecurityParameters {
    public var version(get, never):Int32;
    public var useRSA(get, never):Bool;

    public static inline var COMPRESSION_NULL = 0;

    // COMPRESSION

    // This is probably not smart. Revise this to use all settings from TLSConfig, since this shouldn't really know about
    // user settings, those are best handled from the engine at a session level.
    public static var IGNORE_CN_MISMATCH:Bool = true;
    public static var ENABLE_USER_CLIENT_CERTIFICATE:Bool = false;
    public static var USER_CERTIFICATE:String;


    private var cert:ByteArray; // Local Cert  
    private var key:RSAKey; // local key  
    private var entity:Int32; // SERVER | CLIENT  
    private var bulkCipher:Int32; // BULK_CIPHER_*  
    private var cipherType:Int32; // STREAM_CIPHER | BLOCK_CIPHER  
    private var keySize:Int32;
    private var keyMaterialLength:Int32;
    private var IVSize:Int32;
    private var macAlgorithm:Int32; // MAC_*  
    private var hashSize:Int32;
    private var compression:Int32; // COMPRESSION_NULL  
    private var masterSecret:ByteArray; // 48 bytes  
    private var clientRandom:ByteArray; // 32 bytes  
    private var serverRandom:ByteArray; // 32 bytes  
    private var ignoreCNMismatch:Bool = true;
    private var trustAllCerts:Bool = false;
    private var trustSelfSigned:Bool = false;
    public static inline var PROTOCOL_VERSION:Int32 = 0x0301;
    private var tlsDebug:Bool = false;


    // not strictly speaking part of this, but yeah.
    public var keyExchange:Int32;

    public function new(entity:Int32, localCert:ByteArray = null, localKey:RSAKey = null) {
        this.entity = entity;
        reset();
        key = localKey;
        cert = localCert;
    }

    private function get_Version():Int32 {
        return PROTOCOL_VERSION;
    }

    public function reset():Void {
        bulkCipher = BulkCiphers.NULL;
        cipherType = BulkCiphers.BLOCK_CIPHER;
        macAlgorithm = MACs.NULL;
        compression = COMPRESSION_NULL;
        masterSecret = null;
    }

    public function getBulkCipher():Int32 {
        return bulkCipher;
    }

    public function getCipherType():Int32 {
        return cipherType;
    }

    public function getMacAlgorithm():Int32 {
        return macAlgorithm;
    }

    public function setCipher(cipher:Int32):Void {
        bulkCipher = CipherSuites.getBulkCipher(cipher);
        cipherType = BulkCiphers.getType(bulkCipher);
        keySize = BulkCiphers.getExpandedKeyBytes(bulkCipher); // 8  
        keyMaterialLength = BulkCiphers.getKeyBytes(bulkCipher); // 5  
        IVSize = BulkCiphers.getIVSize(bulkCipher);

        keyExchange = CipherSuites.getKeyExchange(cipher);

        macAlgorithm = CipherSuites.getMac(cipher);
        hashSize = MACs.getHashSize(macAlgorithm);
    }

    public function setCompression(algo:Int32):Void {
        compression = algo;
    }

    public function setPreMasterSecret(secret:ByteArray):Void {
        // compute master_secret
        var seed:ByteArray = new ByteArray();
        seed.writeBytes(clientRandom, 0, clientRandom.length);
        seed.writeBytes(serverRandom, 0, serverRandom.length);
        var prf:TLSPRF = new TLSPRF(secret, "master secret", seed);
        masterSecret = new ByteArray();
        prf.nextBytes(masterSecret, 48);
        if (tlsDebug)
            trace("Master Secret: " + Hex.fromArray(masterSecret, true));
    }

    public function setClientRandom(secret:ByteArray):Void {
        clientRandom = secret;
    }

    public function setServerRandom(secret:ByteArray):Void {
        serverRandom = secret;
    }

    private function get_UseRSA():Bool {
        return KeyExchanges.useRSA(keyExchange);
    }

    public function computeVerifyData(side:Int32, handshakeMessages:ByteArray):ByteArray {
        var seed:ByteArray = new ByteArray();
        var md5:MD5 = new MD5();
        if (tlsDebug)
            trace("Handshake value: " + Hex.fromArray(handshakeMessages, true));
        seed.writeBytes(md5.hash(handshakeMessages), 0, md5.getHashSize());
        var sha:SHA1 = new SHA1();
        seed.writeBytes(sha.hash(handshakeMessages), 0, sha.getHashSize());
        if (tlsDebug)
            trace("Seed in: " + Hex.fromArray(seed, true));
        var prf:TLSPRF = new TLSPRF(masterSecret, ((side == TLSEngine.CLIENT)) ? "client finished" : "server finished", seed);
        var out:ByteArray = new ByteArray();
        prf.nextBytes(out, 12);
        if (tlsDebug)
            trace("Finished out: " + Hex.fromArray(out, true));
        out.position = 0;
        return out;
    }

    // client side certficate check - This is probably incorrect somehow

    public function computeCertificateVerify(side:Int32, handshakeMessages:ByteArray):ByteArray {
        var seed:ByteArray = new ByteArray();
        var md5:MD5 = new MD5();
        seed.writeBytes(md5.hash(handshakeMessages), 0, md5.getHashSize());
        var sha:SHA1 = new SHA1();
        seed.writeBytes(sha.hash(handshakeMessages), 0, sha.getHashSize());

        // Now that I have my hashes of existing handshake messages (which I'm not sure about the length of yet) then
        // Sign that with my private key
        seed.position = 0;
        var out:ByteArray = new ByteArray();
        key.sign(seed, out, seed.bytesAvailable);
        out.position = 0;
        return out;
    }

    public function getConnectionStates():ConnectionStateRW {
        if (masterSecret != null) {
            var seed:ByteArray = new ByteArray();
            seed.writeBytes(serverRandom, 0, serverRandom.length);
            seed.writeBytes(clientRandom, 0, clientRandom.length);
            var prf = new TLSPRF(masterSecret, "key expansion", seed);

            var client_write_MAC = prf.getNextBytes(hashSize);
            var server_write_MAC = prf.getNextBytes(hashSize);
            var client_write_key = prf.getNextBytes(keyMaterialLength);
            var server_write_key = prf.getNextBytes(keyMaterialLength);
            var client_write_IV = prf.getNextBytes(IVSize);
            var server_write_IV = prf.getNextBytes(IVSize);

            var client_write = new TLSConnectionState(
                bulkCipher, cipherType, macAlgorithm,
                client_write_MAC, client_write_key, client_write_IV
            );

            var server_write = new TLSConnectionState(
                bulkCipher, cipherType, macAlgorithm,
                server_write_MAC, server_write_key, server_write_IV
            );

            if (entity == TLSEngine.CLIENT) {
                return new ConnectionStateRW(server_write, client_write);
            } else {
                return new ConnectionStateRW(client_write, server_write);
            }
        }
        else {
            return new ConnectionStateRW(new TLSConnectionState(), new TLSConnectionState());
        }
    }
}
