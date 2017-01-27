/**
 * ISecurityParameters
 * 
 * This class encapsulates all the security parameters that get negotiated
 * during the TLS handshake. It also holds all the key derivation methods.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import haxe.Int32;
import com.hurlant.util.ByteArray;

interface ISecurityParameters {
    var version(get, never):Int32;
    var useRSA(get, never):Bool;

    function reset():Void;
    function getBulkCipher():Int32;
    function getCipherType():Int32;
    function getMacAlgorithm():Int32;
    function setCipher(cipher:Int32):Void;
    function setCompression(algo:Int32):Void;
    function setPreMasterSecret(secret:ByteArray):Void;
    function setClientRandom(secret:ByteArray):Void;
    function setServerRandom(secret:ByteArray):Void;
    function computeVerifyData(side:Int32, handshakeMessages:ByteArray):ByteArray;
    function computeCertificateVerify(side:Int32, handshakeRecords:ByteArray):ByteArray;
    function getConnectionStates():ConnectionStateRW;
}
