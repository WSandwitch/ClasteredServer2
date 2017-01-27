/**
 * TLSEngine
 * 
 * A TLS protocol implementation.
 * See comment below for some details.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Patched(heavily) by Bobby Parker (shortwave[at]gmail.com)
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import com.hurlant.util.ProgressEvent;
import com.hurlant.util.ArrayUtil;
import com.hurlant.crypto.prng.Random;
import haxe.Int32;
import com.hurlant.crypto.cert.X509Certificate;
import com.hurlant.crypto.cert.X509CertificateCollection;

import com.hurlant.util.Event;
import flash.events.EventDispatcher;
import com.hurlant.util.ByteArray;
import com.hurlant.util.IDataInput;
import com.hurlant.util.IDataOutput;
import flash.utils.ClearTimeout;
import flash.utils.SetTimeout;

@:meta(Event(name = "close", type = "flash.events.Event"))

@:meta(Event(name = "socketData", type = "flash.events.ProgressEvent"))

@:meta(Event(name = "ready", type = "com.hurlant.crypto.tls.TLSEvent"))

@:meta(Event(name = "data", type = "com.hurlant.crypto.tls.TLSEvent"))


/**
 * The heart of the TLS protocol.
 * This class can work in server or client mode.
 *
 * This doesn't fully implement the TLS protocol.
 *
 * Things missing that I'd like to add:
 * - support for client-side certificates
 * - general code clean-up to make sure we don't have gaping securite holes
 *
 * Things that aren't there that I won't add:
 * - support for "export" cypher suites (deprecated in later TLS versions)
 * - support for "anon" cypher suites (deprecated in later TLS versions)
 *
 * Things that I'm unsure about adding later:
 * - compression. Compressing encrypted streams is barely worth the CPU cycles.
 * - diffie-hellman based key exchange mechanisms. Nifty, but would we miss it?
 *
 * @author henri
 *
 */
class TLSEngine extends EventDispatcher {
    public static inline var SERVER = 0;
    public static inline var CLIENT = 1;

    private static inline var PROTOCOL_HANDSHAKE = 22;
    private static inline var PROTOCOL_ALERT = 21;
    private static inline var PROTOCOL_CHANGE_CIPHER_SPEC = 20;
    private static inline var PROTOCOL_APPLICATION_DATA = 23;

    private static inline var STATE_NEW = 0; // brand new. nothing happened yet
    private static inline var STATE_NEGOTIATING = 1; // we're figuring out what to use
    private static inline var STATE_READY = 2; // we're ready for AppData stuff to go over us.
    private static inline var STATE_CLOSED = 3; // we're done done.

    public var peerCertificate(get, never):X509Certificate;

    public var protocol_version:Int32;

    private var _entity:Int32; // SERVER | CLIENT  
    private var _config:TLSConfig;

    private var _state:Int32;

    private var _securityParameters:ISecurityParameters;

    private var _currentReadState:IConnectionState;
    private var _currentWriteState:IConnectionState;
    private var _pendingReadState:IConnectionState;
    private var _pendingWriteState:IConnectionState;

    private var _handshakePayloads:ByteArray;
    private var _handshakeRecords:ByteArray; // For client-side certificate verify  

    private var _iStream:IDataInput;
    private var _oStream:IDataOutput;

    // temporary store for X509 certs received by this engine.
    private var _store:X509CertificateCollection;
    // the main certificate received from the other side.
    private var _otherCertificate:X509Certificate;

    private function get_PeerCertificate():X509Certificate {
        return _otherCertificate;
    }
    // If this isn't null, we expect this identity to be found in the Cert's Subject CN.
    private var _otherIdentity:String;

    // The client-side cert
    private var _myCertficate:X509Certificate;
    // My Identity
    private var _myIdentity:String;

    /**
     * 
     * @param config		A TLSConfig instance describing how we're supposed to work
     * @param iStream		An input stream to read TLS data from
     * @param oStream		An output stream to write TLS data to
     * @param otherIdentity	An optional identifier. If set, this will be checked against the Subject CN of the other side's certificate.
     * 
     */

    private function new(config:TLSConfig, iStream:IDataInput, oStream:IDataOutput, otherIdentity:String = null) {
        super();

        handshakeHandlersClient = new Map<Int, Dynamic>();
        handshakeHandlersClient[0] = parseHandshakeHello;
        handshakeHandlersClient[1] = notifyStateError;
        handshakeHandlersClient[2] = parseHandshakeServerHello;
        handshakeHandlersClient[11] = loadCertificates;
        handshakeHandlersClient[12] = parseServerKeyExchange;
        handshakeHandlersClient[13] = setStateRespondWithCertificate;
        handshakeHandlersClient[14] = sendClientAck;
        handshakeHandlersClient[15] = notifyStateError;
        handshakeHandlersClient[16] = notifyStateError;
        handshakeHandlersClient[20] = verifyHandshake;

        handshakeHandlersServer = new Map<Int, Dynamic>();
        handshakeHandlersServer[0] = notifyStateError;
        handshakeHandlersServer[1] = parseHandshakeClientHello;
        handshakeHandlersServer[2] = notifyStateError;
        handshakeHandlersServer[11] = loadCertificates;
        handshakeHandlersServer[12] = notifyStateError;
        handshakeHandlersServer[13] = notifyStateError;
        handshakeHandlersServer[14] = notifyStateError;
        handshakeHandlersServer[15] = notifyStateError;
        handshakeHandlersServer[16] = parseHandshakeClientKeyExchange;
        handshakeHandlersServer[20] = verifyHandshake;

        protocolHandlers = new Map<Int, Dynamic>();
        protocolHandlers[23] = parseApplicationData;
        protocolHandlers[22] = parseHandshake;
        protocolHandlers[21] = parseAlert;
        protocolHandlers[20] = parseChangeCipherSpec;

        _entity = config.entity;
        _config = config;
        _iStream = iStream;
        _oStream = oStream;
        _otherIdentity = otherIdentity;

        _state = STATE_NEW;

        // Pick the right set of callbacks
        _entityHandshakeHandlers = _entity == (CLIENT != 0) ? handshakeHandlersClient : handshakeHandlersServer;

        // setting up new security parameters needs to be controlled by...something.
        if (_config.version == SSLSecurityParameters.PROTOCOL_VERSION) {
            _securityParameters = new SSLSecurityParameters(_entity);
        }
        else {
            _securityParameters = new TLSSecurityParameters(_entity, _config.certificate, _config.privateKey);
        }
        protocol_version = _config.version;

        // So this...why is it here, other than to preclude a possible null pointer situation?
        var states:Dynamic = _securityParameters.getConnectionStates();

        _currentReadState = states.read;
        _currentWriteState = states.write;

        _handshakePayloads = new ByteArray();

        _store = new X509CertificateCollection();
    }

    /**
     * This starts the TLS negotiation for a TLS Client.
     * 
     * This is a no-op for a TLS Server.
     * 
     */

    public function start():Void {
        if (_entity == CLIENT) {
            try {
                startHandshake();
            } catch (e:TLSError) {
                handleTLSError(e);
            }
        }
    }


    public function dataAvailable(e:Dynamic = null):Void {
        if (_state == STATE_CLOSED) return; // ignore
        try {
            parseRecord(_iStream);
        } catch (e:TLSError) {
            handleTLSError(e);
        }
    }

    public function close(e:TLSError = null):Void {
        if (_state == STATE_CLOSED) return // ok. send an Alert to let the peer know    // ignore  ;

        var rec:ByteArray = new ByteArray();
        if (e == null && _state != STATE_READY) {
            // use canceled while handshaking. be nice about it
            rec[0] = 1;
            rec[1] = TLSError.user_canceled;
            sendRecord(PROTOCOL_ALERT, rec);
        }
        rec[0] = 2;
        if (e == null) {
            rec[1] = TLSError.close_notify;
        } else {
            rec[1] = e.errorID;
            trace("TLSEngine shutdown triggered by " + e);
        }
        sendRecord(PROTOCOL_ALERT, rec);

        _state = STATE_CLOSED;
        dispatchEvent(new Event(Event.CLOSE));
    }

    private var _packetQueue:Array<Dynamic> = [];

    private function parseRecord(stream:IDataInput):Void {
        var p:ByteArray;
        while (_state != STATE_CLOSED && stream.bytesAvailable > 4) {

            if (_packetQueue.length > 0) {
                var packet:Dynamic = _packetQueue.shift();
                p = packet.data;
                if (stream.bytesAvailable + p.length >= packet.length) {
                    // we have a whole packet. put together.
                    stream.readBytes(p, p.length, packet.length - p.length);
                    parseOneRecord(packet.type, packet.length, p);
                    // do another loop to parse any leftover record
                    continue;
                } else {
                    // not enough. grab the data and park it.
                    stream.readBytes(p, p.length, stream.bytesAvailable);
                    _packetQueue.push(packet);
                    continue;
                }
            }


            var type = stream.readByte();
            var ver = stream.readShort();
            var length = stream.readShort();

            // support compression and encryption overhead.
            if (length > 16384 + 2048) {
                throw new TLSError("Excessive TLS Record length: " + length, TLSError.record_overflow);
            }

            // Can pretty much assume that if I'm here, I've got a default config, so let's use it.
            if (ver != _securityParameters.version) {
                throw new TLSError("Unsupported TLS version: $ver", TLSError.protocol_version);
            }

            p = new ByteArray();
            var actualLength:Int32 = Math.min(stream.bytesAvailable, length);
            stream.readBytes(p, 0, actualLength);
            if (actualLength == length) {
                parseOneRecord(type, length, p);
            }
            else {
                _packetQueue.push({
                    type : type,
                    length : length,
                    data : p,

                });
            }
        }
    }


    // Protocol handler map, provides a mapping of protocol types to individual packet handlers

    private var protocolHandlers:Map<Int, Dynamic> = null;

    /**
     * Modified to support the notion of a handler map(see above ), since it makes for better clarity (IMHO of course).
     */

    private function parseOneRecord(type:Int32, length:Int32, p:ByteArray):Void {
        p = _currentReadState.decrypt(type, length, p);
        if (p.length > 16384) {
            throw new TLSError("Excessive Decrypted TLS Record length: " + p.length, TLSError.record_overflow);
        }
        if (protocolHandlers.exists(type)) {
            while (p != null) p = protocolHandlers[type](p);
        } else {
            throw new TLSError("Unsupported TLS Record Content Type: $type", TLSError.unexpected_message);
        }
    }

    ///////// handshake handling
    // session identifier
    // peer certificate
    // compression method
    // cipher spec
    // master secret
    // is resumable
    private static inline var HANDSHAKE_HELLO_REQUEST = 0;
    private static inline var HANDSHAKE_CLIENT_HELLO = 1;
    private static inline var HANDSHAKE_SERVER_HELLO = 2;
    private static inline var HANDSHAKE_CERTIFICATE = 11;
    private static inline var HANDSHAKE_SERVER_KEY_EXCHANGE = 12;
    private static inline var HANDSHAKE_CERTIFICATE_REQUEST = 13;
    private static inline var HANDSHAKE_HELLO_DONE = 14;
    private static inline var HANDSHAKE_CERTIFICATE_VERIFY = 15;
    private static inline var HANDSHAKE_CLIENT_KEY_EXCHANGE = 16;
    private static inline var HANDSHAKE_FINISHED = 20;

    // Server handshake handler map
    private var handshakeHandlersServer:Map<Int, Dynamic> = null;

    // Client handshake handler map
    private var handshakeHandlersClient:Map<Int, Dynamic> = null;
    private var _entityHandshakeHandlers:Dynamic;
    private var _handshakeCanContinue:Bool = true; // For handling cases where I might need to pause processing during a handshake (cert issues, etc.).  
    private var _handshakeQueue:Array<Dynamic> = [];

    /**
     * The handshake is always started by the client.
     */

    private function startHandshake():Void {
        _state = STATE_NEGOTIATING;
        // reset some other handshake state. XXX
        sendClientHello();
    }

    /**
     * Handle the incoming handshake packet.
     *
     */

    private function parseHandshake(p:ByteArray):ByteArray {

        if (p.length < 4) {
            trace("Handshake packet is way too short. bailing.");
            return null;
        }

        p.position = 0;

        var rec:ByteArray = p;
        var type:Int32 = rec.readUnsignedByte();
        var tmp:Int32 = rec.readUnsignedByte();
        var length:Int32 = (tmp << 16) | rec.readUnsignedShort();

        if (length + 4 > p.length) {
            // partial read.
            trace("Handshake packet is incomplete. bailing.");
            return null;
        }

        // we need to copy the record, to have a valid FINISHED exchange.

        if (type != HANDSHAKE_FINISHED) {
            _handshakePayloads.writeBytes(p, 0, length + 4);
        }

        // is required, as was the case using the switch statement. BP    // about the incoming packet type, so no previous handling or massaging of the data    // I modified the individual handlers so they encapsulate all possible knowledge    // Surf the handler map and find the right handler for this handshake packet type.


        if (!_entityHandshakeHandlers.exists(type)) {
            throw new TLSError("Unimplemented or unknown handshake type!", TLSError.internal_error);
        } // Get set up for the next packet.

        _entityHandshakeHandlers[type](rec);


        if (length + 4 < p.length) {
            var n:ByteArray = new ByteArray();
            n.writeBytes(p, length + 4, p.length - (length + 4));
            return n;
        }
        else {
            return null;
        }
    }

    /**
     * Throw an error when the detected handshake state isn't a valid state for the given entity type (client vs. server, etc. ).
     * This really should abort the handshake, since there's no case in which a server should EVER be confused about the type of entity it is. BP
     */

    private function notifyStateError(rec:ByteArray):Void {
        throw new TLSError("Invalid handshake state for a TLS Entity type of " + _entity, TLSError.internal_error);
    }

    /**
     * two unimplemented functions
     */

    private function parseClientKeyExchange(rec:ByteArray):Void {
        throw new TLSError("ClientKeyExchange is currently unimplemented!", TLSError.internal_error);
    }

    private function parseServerKeyExchange(rec:ByteArray):Void {
        throw new TLSError("ServerKeyExchange is currently unimplemented!", TLSError.internal_error);
    }

    /**
     * Test the server's Finished message for validity against the data we know about. Only slightly rewritten. BP
     */

    private function verifyHandshake(rec:ByteArray):Void {
        // Get the Finished message
        var verifyData = new ByteArray();
        // This, in the vain hope that noboby is using SSL 2 anymore
        if (_securityParameters.version == SSLSecurityParameters.PROTOCOL_VERSION) {
            rec.readBytes(verifyData, 0, 36);
        } else { // presuming TLS
            rec.readBytes(verifyData, 0, 12);
        }

        var data = _securityParameters.computeVerifyData(1 - _entity, _handshakePayloads);

        if (ArrayUtil.equals(verifyData, data)) {
            _state = STATE_READY;
            dispatchEvent(new TLSEvent(TLSEvent.READY));
        } else {
            throw new TLSError("Invalid Finished mac.", TLSError.bad_record_mac);
        }
    }

    // enforceClient/enforceServer removed in favor of state-driven function maps

    /**
     * Handle a HANDSHAKE_HELLO
     */

    private function parseHandshakeHello(rec:ByteArray):Void {
        if (_state != STATE_READY) {
            trace("Received an HELLO_REQUEST before being in state READY. ignoring.");
            return;
        }
        _handshakePayloads = new ByteArray();
        startHandshake();
    }

    /**
     * Handle a HANDSHAKE_CLIENT_KEY_EXCHANGE
     */

    private function parseHandshakeClientKeyExchange(rec:ByteArray):Void {
        if (!_securityParameters.useRSA) {
            throw new TLSError("parseHandshakeClientKeyExchange not implemented for DH modes.", TLSError.internal_error);
        }

        // skip 2 bytes for length.
        var len = rec.readShort();
        var cipher = new ByteArray();
        rec.readBytes(cipher, 0, len);
        var preMasterSecret:ByteArray = new ByteArray();
        _config.privateKey.decrypt(cipher, preMasterSecret, len);
        _securityParameters.setPreMasterSecret(preMasterSecret);

        // now is a good time to get our pending states
        var o:Dynamic = _securityParameters.getConnectionStates();
        _pendingReadState = o.read;
        _pendingWriteState = o.write;
    }

    /** 
     * Handle HANDSHAKE_SERVER_HELLO - client-side
     */

    private function parseHandshakeServerHello(rec:IDataInput):Void {
        var ver:Int32 = rec.readShort();
        if (ver != _securityParameters.version) {
            throw new TLSError("Unsupported TLS version: $ver", TLSError.protocol_version);
        }
        var random:ByteArray = new ByteArray();
        rec.readBytes(random, 0, 32);
        var session_length:Int32 = rec.readByte();
        var session:ByteArray = new ByteArray();
        if (session_length > 0) {
            // some implementations don't assign a session ID
            rec.readBytes(session, 0, session_length);
        }

        _securityParameters.setCipher(rec.readShort());
        _securityParameters.setCompression(rec.readByte());
        _securityParameters.setServerRandom(random);
    }

    /**
     *  Handle HANDSHAKE_CLIENT_HELLO - server side
     */

    private function parseHandshakeClientHello(rec:IDataInput):Void {
        var ver = rec.readShort();
        if (ver != _securityParameters.version) {
            throw new TLSError("Unsupported TLS version: $ver", TLSError.protocol_version);
        }

        var random = new ByteArray();
        rec.readBytes(random, 0, 32);
        var session_length:Int32 = rec.readByte();
        var session:ByteArray = new ByteArray();
        if (session_length > 0) {
            // some implementations don't assign a session ID
            rec.readBytes(session, 0, session_length);
        }
        var suites = [];

        var suites_length = rec.readShort();
        for (i in 0...suites_length / 2) {
            suites.push(rec.readShort());
        }

        var compressions = [];

        var comp_length = rec.readByte();
        for (i in 0...comp_length) {
            compressions.push(rec.readByte());
        }

        var ret = {
            random : random,
            session : session,
            suites : suites,
            compressions : compressions
        };

        var sofar:Int32 = 2 + 32 + 1 + session_length + 2 + suites_length + 1 + comp_length;
        var extensions:Array<Dynamic> = [];
        if (sofar < length) {
            // we have extensions. great.
            var ext_total_length:Int32 = rec.readShort();
            while (ext_total_length > 0) {
                var ext_type = rec.readShort();
                var ext_length = rec.readShort();
                var ext_data = new ByteArray();
                rec.readBytes(ext_data, 0, ext_length);
                ext_total_length -= 4 + ext_length;
                extensions.push({
                    type : ext_type,
                    length : ext_length,
                    data : ext_data,
                });
            }
        }
        ret.ext = extensions;

        sendServerHello(ret);
        sendCertificate();
        // TODO: Modify to handle case of requesting a certificate from the client, for "client authentication",
        // and testing purposes, will probably never actually need it.
        sendServerHelloDone();
    }

    private function sendClientHello() {
        var rec = new ByteArray();
        // version - modified to support version attribute from ISecurityParameters
        rec.writeShort(_securityParameters.version);
        // random
        var clientRandom = Random.getStaticRandomBytes(32);
        _securityParameters.setClientRandom(clientRandom.clone());
        rec.writeBytes(clientRandom.clone());
        // session
        rec.writeByte(32);
        rec.writeBytes(Random.getStaticRandomBytes(32));
        // Cipher suites
        var cs = _config.cipherSuites;
        rec.writeShort(2 * cs.length);
        for (i in 0...cs.length) rec.writeShort(cs[i]); // Compression

        cs = _config.compressions;
        rec.writeByte(cs.length);
        for (i in 0...cs.length) rec.writeByte(cs[i]); // no extensions, yet.

        rec.position = 0;
        sendHandshake(HANDSHAKE_CLIENT_HELLO, rec.length, rec);
    }

    private function findMatch(a1:Array<Int32>, a2:Array<Int32>):Int32 {
        for (i in 0...a1.length) {
            var e = a1[i];
            if (Lambda.indexOf(a2, e) > -1) return e;
        }
        return -1;
    }

    private function sendServerHello(v:Dynamic):Void {
        var cipher = findMatch(_config.cipherSuites, v.suites);
        if (cipher == -1) {
            throw new TLSError("No compatible cipher found.", TLSError.handshake_failure);
        }
        _securityParameters.setCipher(cipher);

        var comp = findMatch(_config.compressions, v.compressions);
        if (comp == 01) {
            throw new TLSError("No compatible compression method found.", TLSError.handshake_failure);
        }
        _securityParameters.setCompression(comp);
        _securityParameters.setClientRandom(v.random);


        var rec:ByteArray = new ByteArray();
        rec.writeShort(_securityParameters.version);
        var serverRandom = Random.getStaticRandomBytes(32);
        _securityParameters.setServerRandom(serverRandom);
        rec.writeBytes(serverRandom);
        // session
        rec.writeByte(32);
        rec.writeBytes(Random.getStaticRandomBytes(32));
        // Cipher suite
        rec.writeShort(v.suites[0]);
        // Compression
        rec.writeByte(v.compressions[0]);
        rec.position = 0;
        sendHandshake(HANDSHAKE_SERVER_HELLO, rec.length, rec);
    }

    private var sendClientCert:Bool = false;

    private function setStateRespondWithCertificate(r:ByteArray = null):Void {
        sendClientCert = true;
    }

    private function sendCertificate(r:ByteArray = null):Void {
        var cert:ByteArray = _config.certificate;
        var len:Int32;
        var len2:Int32;
        var rec:ByteArray = new ByteArray();
        // Look for a certficate chain, if we have one, send it, if we don't, send an empty record.
        if (cert != null) {
            len = cert.length;
            len2 = cert.length + 3;
            rec.writeInt24(len2);
            rec.writeInt24(len);
            rec.writeBytes(cert);
        } else {
            rec.writeInt24(0);
        }
        rec.position = 0;
        sendHandshake(HANDSHAKE_CERTIFICATE, rec.length, rec);
    }

    private function sendCertificateVerify():Void {
        var rec:ByteArray = new ByteArray();
        // Encrypt the handshake payloads here
        var data = _securityParameters.computeCertificateVerify(_entity, _handshakePayloads);
        data.position = 0;
        sendHandshake(HANDSHAKE_CERTIFICATE_VERIFY, data.length, data);
    }

    private function sendServerHelloDone():Void {
        var rec:ByteArray = new ByteArray();
        sendHandshake(HANDSHAKE_HELLO_DONE, rec.length, rec);
    }

    private function sendClientKeyExchange():Void {
        if (!_securityParameters.useRSA) {
            throw new TLSError("Non-RSA Client Key Exchange not implemented.", TLSError.internal_error);
        }

        var p:ByteArray = new ByteArray();
        p.writeShort(_securityParameters.version);
        var prng:Random = new Random();
        prng.nextBytes(p, 46);
        p.position = 0;

        var preMasterSecret:ByteArray = new ByteArray();
        preMasterSecret.writeBytes(p, 0, p.length);
        preMasterSecret.position = 0;
        _securityParameters.setPreMasterSecret(preMasterSecret);

        var enc_key:ByteArray = new ByteArray();
        _otherCertificate.getPublicKey().encrypt(preMasterSecret, enc_key, preMasterSecret.length);

        enc_key.position = 0;
        var rec = new ByteArray();

        // TLS requires the size of the premaster key be sent BUT
        // SSL 3.0 does not
        if (_securityParameters.version > 0x0300) rec.writeShort(enc_key.length);
        rec.writeBytes(enc_key, 0, enc_key.length);

        rec.position = 0;

        sendHandshake(HANDSHAKE_CLIENT_KEY_EXCHANGE, rec.length, rec);

        // now is a good time to get our pending states
        var o = _securityParameters.getConnectionStates();
        _pendingReadState = o.read;
        _pendingWriteState = o.write;
    }

    private function sendFinished():Void {
        var data = _securityParameters.computeVerifyData(_entity, _handshakePayloads);
        data.position = 0;
        sendHandshake(HANDSHAKE_FINISHED, data.length, data);
    }

    private function sendHandshake(type:Int32, len:Int32, payload:IDataInput):Void {
        var rec = new ByteArray();
        rec.writeByte(type);
        rec.writeByte(0);
        rec.writeShort(len);
        payload.readBytes(rec, rec.position, len);
        _handshakePayloads.writeBytes(rec, 0, rec.length);
        sendRecord(PROTOCOL_HANDSHAKE, rec);
    }

    private function sendChangeCipherSpec():Void {
        sendRecord(PROTOCOL_CHANGE_CIPHER_SPEC, ByteArray.fromBytesArray([1]));

        // right after, switch the cipher for writing.
        _currentWriteState = _pendingWriteState;
        _pendingWriteState = null;
    }

    public function sendApplicationData(data:ByteArray, offset:Int32 = 0, length:Int32 = 0):Void {
        var rec:ByteArray = new ByteArray();
        var len:Int32 = length;
        // BIG FAT WARNING: Patch from Arlen Cuss ALA As3crypto group on Google code.
        // This addresses data overflow issues when the packet size hits the max length boundary.
        if (len == 0) len = data.length;
        while (len > 16384) {
            rec.position = rec.length = 0;
            rec.writeBytes(data, offset, 16384);
            rec.position = 0;
            sendRecord(PROTOCOL_APPLICATION_DATA, rec);
            offset += 16384;
            len -= 16384;
        }
        rec.position = rec.length = 0;
        rec.writeBytes(data, offset, len);
        // trace("Data I'm sending..." + Hex.fromArray( data ));
        rec.position = 0;
        sendRecord(PROTOCOL_APPLICATION_DATA, rec);
    }

    private function sendRecord(type:Int32, payload:ByteArray):Void {
        // encrypt
        payload = _currentWriteState.encrypt(type, payload);

        _oStream.writeByte(type);
        _oStream.writeShort(_securityParameters.version);
        _oStream.writeShort(payload.length);
        _oStream.writeBytes(payload);

        scheduleWrite();
    }

    private var _writeScheduler:Int32;

    private function scheduleWrite():Void {
        if (_writeScheduler != 0) return;
        _writeScheduler = setTimeout(commitWrite, 0);
    }

    private function commitWrite():Void {
        clearTimeout(_writeScheduler);
        _writeScheduler = 0;
        if (_state != STATE_CLOSED) {
            dispatchEvent(new ProgressEvent(ProgressEvent.SOCKET_DATA));
        }
    }

    private function sendClientAck(rec:ByteArray):Void {
        if (!_handshakeCanContinue) return;

        // If I have a pending cert request, send it
        if (sendClientCert) sendCertificate(); // send a client key exchange

        sendClientKeyExchange();
        // Send the certificate verify, if we have one
        if (_config.certificate != null) sendCertificateVerify(); // send a change cipher spec

        sendChangeCipherSpec();
        // send a finished
        sendFinished();
    }

    /**
     * Vaguely gross function that parses a RSA key out of a certificate.
     *
     * As long as that certificate looks just the way we expect it to.
     */

    private function loadCertificates(rec:ByteArray):Void {
        var tmp:Int32 = rec.readUnsignedByte();
        var certs_len = (tmp << 16) | rec.readShort();
        var certs:Array<Dynamic> = [];

        while (certs_len > 0) {
            tmp = rec.readByte();
            var cert_len:Int32 = (tmp << 16) | rec.readShort();
            var cert:ByteArray = new ByteArray();
            rec.readBytes(cert, 0, cert_len);
            certs.push(cert);
            certs_len -= 3 + cert_len;
        }

        var firstCert:X509Certificate = null;
        for (i in 0...certs.length) {
            var x509:X509Certificate = new X509Certificate(certs[i]);
            _store.addCertificate(x509);
            if (firstCert == null) firstCert = x509;
        } // This nice trust override stuff comes from Joey Parrish via As3crypto forums    // Test first for trust override parameters


        var certTrusted = if (_config.trustAllCertificates) {
            true;
        } else if (_config.trustSelfSignedCertificates) { // Good so far
            firstCert.isSelfSigned(Date.now()); // Self-signed certs
        } else {
            firstCert.isSigned(_store, _config.CAStore); // Certs with a signer in the CA store - realistically, I should setup an event chain to handle this
        }

        if (certTrusted) {
            // ok, that's encouraging. now for the hostname match.
            if (_otherIdentity == null || _config.ignoreCommonNameMismatch) {
                // we don't care who we're talking with. groovy.
                _otherCertificate = firstCert;
            } else {
                // use regex to handle wildcard certs
                var commonName = firstCert.getCommonName();

                // replace the asterisk and first dot with a regex sequence to match one or more non-dot characters followed by a dot
                // this allows the wildcard cert to match a naked domain ( mydomain.com ) and subdomains (sub.mydomain.com)
                //var commonNameRegex:RegExp = new RegExp( commonName.replace(/[\^\\\-$.[\]|()?+{}]/g, "\\$&").replace(/\*\\\./g, "([^.]+\.)?"), "gi");
                var commonNameRegex = new RegExp(commonName.replace(new EReg('[\\^\\\\\\-$.[\\]|()?+{}]', "g"), "\\$&").replace(new EReg('\\*', "g"), "([^.]+\.)?"), "gi");
                if (commonNameRegex.exec(_otherIdentity)) {
                    _otherCertificate = firstCert;
                }
                else {
                    if (_config.promptUserForAcceptCert) {
                        _handshakeCanContinue = false;
                        dispatchEvent(new TLSEvent(TLSEvent.PROMPT_ACCEPT_CERT));
                    } else {
                        throw new TLSError("Invalid common name: " + firstCert.getCommonName() + ", expected " + _otherIdentity, TLSError.bad_certificate);
                    }
                }
            }
        } else {
            // Let's ask the user if we can accept this cert. I'm not certain of the behaviour in case of timeouts,
            // so I probably need to handle the case by killing and restarting the connection rather than continuing if it becomes
            // an issue. We shall see. BP
            if (_config.promptUserForAcceptCert) {
                _handshakeCanContinue = false;
                dispatchEvent(new TLSEvent(TLSEvent.PROMPT_ACCEPT_CERT));
            } else {
                // Cannot continue, die.
                throw new TLSError("Cannot verify certificate", TLSError.bad_certificate);
            }
        }
    }

    // Accept the peer cert, and keep going

    public function acceptPeerCertificate():Void {
        _handshakeCanContinue = true;
        sendClientAck(null);
    }

    // Step off biotch! No trust for you!

    public function rejectPeerCertificate():Void {
        throw new TLSError("Peer certificate not accepted!", TLSError.bad_certificate);
    }

    private function parseAlert(p:ByteArray):Void {
        //throw new Error("Alert not implemented.");
        // 7.2
        trace("GOT ALERT! type=" + p[1]);
        close();
    }

    private function parseChangeCipherSpec(p:ByteArray):Void {
        p.readUnsignedByte();
        if (_pendingReadState == null) {
            throw new TLSError("Not ready to Change Cipher Spec, damnit.", TLSError.unexpected_message);
        }
        _currentReadState = _pendingReadState;
        _pendingReadState = null;
    }

    private function parseApplicationData(p:ByteArray):Void {
        if (_state != STATE_READY) {
            throw new TLSError("Too soon for data!", TLSError.unexpected_message);
            return;
        }
        dispatchEvent(new TLSEvent(TLSEvent.DATA, p));
    }

    private function handleTLSError(e:TLSError):Void {
        // basic rules to keep things simple:
        // - Make a good faith attempt at notifying peers
        // - TLSErrors are always fatal.
        // BP: Meh...not always. Common Name mismatches appear to be common on servers. Instead of closing, let's pause, and ask for confirmation
        // before we tear the connection down.

        close(e);
    }
}
