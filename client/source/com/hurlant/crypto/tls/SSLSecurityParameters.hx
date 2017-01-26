/**
 * TLSSecurityParameters
 * 
 * This class encapsulates all the security parameters that get negotiated
 * during the TLS handshake. It also holds all the key derivation methods.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import haxe.Int32;
import com.hurlant.crypto.hash.MD5;
import com.hurlant.crypto.hash.SHA1;
import com.hurlant.util.Hex;

import com.hurlant.util.ByteArray;

class SSLSecurityParameters implements ISecurityParameters {
    public var version(get, never):Int32;
    public var useRSA(get, never):Bool;

    // COMPRESSION
    public static inline var COMPRESSION_NULL:Int32 = 0;

    private var entity:Int32; // SERVER | CLIENT
    private var bulkCipher:Int32; // BULK_CIPHER_*
    private var cipherType:Int32; // STREAM_CIPHER | BLOCK_CIPHER
    private var keySize:Int32;
    private var keyMaterialLength:Int32;
    private var keyBlock:ByteArray;
    private var IVSize:Int32;
    private var MAC_length:Int32;
    private var macAlgorithm:Int32; // MAC_*
    private var hashSize:Int32;
    private var compression:Int32; // COMPRESSION_NULL
    private var masterSecret:ByteArray; // 48 bytes
    private var clientRandom:ByteArray; // 32 bytes
    private var serverRandom:ByteArray; // 32 bytes
    private var pad_1:ByteArray; // varies
    private var pad_2:ByteArray; // varies
    private var ignoreCNMismatch:Bool = true;
    private var trustAllCerts:Bool = false;
    private var trustSelfSigned:Bool = false;
    public static inline var PROTOCOL_VERSION:Int32 = 0x0300;

    // not strictly speaking part of this, but yeah.
    public var keyExchange:Int32;

    private function get_Version():Int32 {
        return PROTOCOL_VERSION;
    }

    public function new(entity:Int32, localCert:ByteArray = null, localKey:ByteArray = null) {
        this.entity = entity;
        reset();
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
        pad_1 = new ByteArray();
        pad_2 = new ByteArray();
        for (x in 0...48) {
            pad_1.writeByte(0x36);
            pad_2.writeByte(0x5c);
        }
    }

    public function setCompression(algo:Int32):Void {
        compression = algo;
    }

    public function setPreMasterSecret(secret:ByteArray):Void {
        //  Warning! Following code may cause madness
        //      Tread not here, unless ye be men of valor.
        //
        // ***** Official Prophylactic Comment ******
        //     (to protect the unwary...this code actually works, that's all you need to know)
        //
        // This does two things, computes the master secret, and generates the keyBlock
        //
        // To compute the master_secret, the following algorithm is used.
        //  for SSL 3, this means
        // master = (
        //     MD5( premaster + SHA1('A'   + premaster + client_random + server_random ) ) +
        //     MD5( premaster + SHA1('BB'  + premaster + client_random + server_random ) ) +
        //     MD5( premaster + SHA1('CCC' + premaster + client_random + server_random ) )
        // )
        var tempHashA = new ByteArray(); // temporary hash, gets reused a lot
        var tempHashB = new ByteArray(); // temporary hash, gets reused a lot

        var shaHash:ByteArray;
        var mdHash:ByteArray;

        var i:Int32;
        var j:Int32;

        var sha:SHA1 = new SHA1();
        var md:MD5 = new MD5();

        var k:ByteArray = new ByteArray();

        k.writeBytes(secret);
        k.writeBytes(clientRandom);
        k.writeBytes(serverRandom);

        masterSecret = new ByteArray();
        var pad_char:Int32 = 0x41;

        for (i in 0...3) {
            // SHA portion
            tempHashA.position = 0;

            for (j in 0...i + 1) {
                tempHashA.writeByte(pad_char);
            }
            pad_char++;

            tempHashA.writeBytes(k);
            shaHash = sha.hash(tempHashA);

            // MD5 portion
            tempHashB.position = 0;
            tempHashB.writeBytes(secret);
            tempHashB.writeBytes(shaHash);
            mdHash = md.hash(tempHashB);

            // copy into my key
            masterSecret.writeBytes(mdHash);
        } // Rebuild k (hash seed)    // So here, I'm setting up the keyBlock array that I will derive MACs, keys, and IVs from.    // *************** START KEY BLOCK ****************    // More prophylactic comments    // *************** END MASTER SECRET **************


        k.position = 0;
        k.writeBytes(masterSecret);
        k.writeBytes(serverRandom);
        k.writeBytes(clientRandom);

        keyBlock = new ByteArray();

        tempHashA = new ByteArray();
        tempHashB = new ByteArray();

        // now for 16 iterations to get 256 bytes (16 * 16), better to have more than not enough
        pad_char = 0x41;
        for (i in 0...16) {
            tempHashA.position = 0;
            for (j in 0...i + 1) tempHashA.writeByte(pad_char);

            pad_char++;
            tempHashA.writeBytes(k);
            shaHash = sha.hash(tempHashA);

            tempHashB.position = 0;
            tempHashB.writeBytes(masterSecret);
            tempHashB.writeBytes(shaHash, 0);
            mdHash = md.hash(tempHashB);

            keyBlock.writeBytes(mdHash);
        }
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

    // This is the Finished message
    // if you value your sanity, stay away...far away
    public function computeVerifyData(side:Int32, handshakeMessages:ByteArray):ByteArray {
        // for SSL 3.0, this consists of
        // 	finished = md5( masterSecret + pad2 + md5( handshake + sender + masterSecret + pad1 ) ) +
        //			   sha1( masterSecret + pad2 + sha1( handshake + sender + masterSecret + pad1 ) )
        // trace("Handshake messages: " + Hex.fromArray(handshakeMessages));
        var sha = new SHA1();
        var md = new MD5();
        var k = new ByteArray(); // handshake + sender + masterSecret + pad1
        var j = new ByteArray(); // masterSecret + pad2 + k

        var innerKey:ByteArray;
        var outerKey = new ByteArray();

        var hashSha:ByteArray;
        var hashMD:ByteArray;

        var sideBytes = new ByteArray();
        sideBytes.writeUnsignedInt((side == TLSEngine.CLIENT) ? 0x434C4E54 : 0x53525652);

        // Do the SHA1 part of the routine first
        masterSecret.position = 0;
        k.writeBytes(handshakeMessages);
        k.writeBytes(sideBytes);
        k.writeBytes(masterSecret);
        k.writeBytes(pad_1, 0, 40); // limited to 40 chars for SHA1

        innerKey = sha.hash(k);
        // trace("Inner SHA Key: " + Hex.fromArray(innerKey));

        j.writeBytes(masterSecret);
        j.writeBytes(pad_2, 0, 40); // limited to 40 chars for SHA1
        j.writeBytes(innerKey);

        hashSha = sha.hash(j);
        // trace("Outer SHA Key: " + Hex.fromArray(hashSha));

        // Rebuild k for MD5
        k = new ByteArray();

        k.writeBytes(handshakeMessages);
        k.writeBytes(sideBytes);
        k.writeBytes(masterSecret);
        k.writeBytes(pad_1); // Take the whole length of pad_1 & pad_2 for MD5

        innerKey = md.hash(k);
        // trace("Inner MD5 Key: " + Hex.fromArray(innerKey));

        j = new ByteArray();
        j.writeBytes(masterSecret);
        j.writeBytes(pad_2); // see above re: 48 byte pad
        j.writeBytes(innerKey);

        hashMD = md.hash(j);
        // trace("Outer MD5 Key: " + Hex.fromArray(hashMD));

        outerKey.writeBytes(hashMD, 0, hashMD.length);
        outerKey.writeBytes(hashSha, 0, hashSha.length);
        var out:String = Hex.fromArray(outerKey);
        // trace("Finished Message: " + out);
        outerKey.position = 0;

        return outerKey;
    }

    public function computeCertificateVerify(side:Int32, handshakeMessages:ByteArray):ByteArray {
        // TODO: Implement this, but I don't forsee it being necessary at this point in time, since for purposes
        // of the override, I'm only going to use TLS
        return null;
    }

    public function getConnectionStates():SSLConnectionStateRW {
        if (masterSecret == null) return new SSLConnectionStateRW(new SSLConnectionState(), new SSLConnectionState());
        // so now, I have to derive the actual keys from the keyblock that I generated in setPremasterSecret.
        // for MY purposes, I need RSA-AES 128/256 + SHA
        // so I'm gonna have keylen = 32, minlen = 32, mac_length = 20, iv_length = 16
        // but...I can get this data from the settings returned in the constructor when this object is
        // It strikes me that TLS does this more elegantly...

        var mac_length = this.hashSize;
        var key_length = this.keySize;
        var iv_length = this.IVSize;

        var client_write_MAC = new ByteArray();
        var server_write_MAC = new ByteArray();
        var client_write_key = new ByteArray();
        var server_write_key = new ByteArray();
        var client_write_IV = new ByteArray();
        var server_write_IV = new ByteArray();

        // Derive the keys from the keyblock
        // Get the MACs first
        keyBlock.position = 0;
        keyBlock.readBytes(client_write_MAC, 0, mac_length);
        keyBlock.readBytes(server_write_MAC, 0, mac_length);

        // keyBlock.position is now at MAC_length * 2
        // then get the keys
        keyBlock.readBytes(client_write_key, 0, key_length);
        keyBlock.readBytes(server_write_key, 0, key_length);

        // keyBlock.position is now at (MAC_length * 2) + (keySize * 2)
        // and then the IVs
        keyBlock.readBytes(client_write_IV, 0, iv_length);
        keyBlock.readBytes(server_write_IV, 0, iv_length);

        // reset this in case it's needed, for some reason or another, but I doubt it
        keyBlock.position = 0;

        var client_write = new SSLConnectionState(
            bulkCipher, cipherType, macAlgorithm,
            client_write_MAC, client_write_key, client_write_IV
        );

        var server_write = new SSLConnectionState(
            bulkCipher, cipherType, macAlgorithm,
            server_write_MAC, server_write_key, server_write_IV
        );

        if (entity == TLSEngine.CLIENT) {
            return new SSLConnectionStateRW(server_write, client_write);
        } else {
            return new SSLConnectionStateRW(client_write, server_write);
        }
    }
}
