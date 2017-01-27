/**
 * TLSConfig
 * 
 * A set of configuration parameters for use by a TLSSocket or a TLSEngine.
 * Most parameters are optional and will be set to appropriate default values for most use.
 * 
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import haxe.Int32;
import com.hurlant.util.ByteArray;
import com.hurlant.util.der.PEM;
import com.hurlant.crypto.rsa.RSAKey;
import com.hurlant.crypto.cert.X509CertificateCollection;
import com.hurlant.crypto.cert.MozillaRootCertificates;

class TLSConfig {
    public var entity:Int32; // SERVER | CLIENT  
    
    public var certificate:ByteArray;
    public var privateKey:RSAKey;

    public var cipherSuites:Array<Int32>;

    public var compressions:Array<Dynamic>;
    public var ignoreCommonNameMismatch = false;
    public var trustAllCertificates = false;
    public var trustSelfSignedCertificates = false;
    public var promptUserForAcceptCert = false;
    public var CAStore:X509CertificateCollection;
    public var localKeyStore:X509CertificateCollection;
    public var version:Int32;

    public function new(entity:Int32, cipherSuites:Array<Int32> = null, compressions:Array<Dynamic> = null, certificate:ByteArray = null, privateKey:RSAKey = null, CAStore:X509CertificateCollection = null, ver:Int32 = 0x00) {
        this.entity = entity;
        this.cipherSuites = cipherSuites;
        this.compressions = compressions;
        this.certificate = certificate;
        this.privateKey = privateKey;
        this.CAStore = CAStore;
        this.version = ver;
        // default settings.
        if (cipherSuites == null) this.cipherSuites = CipherSuites.getDefaultSuites();
        if (compressions == null) this.compressions = [TLSSecurityParameters.COMPRESSION_NULL];
        if (CAStore == null) this.CAStore = new MozillaRootCertificates();
        if (ver == 0x00) this.version = TLSSecurityParameters.PROTOCOL_VERSION; // Default to TLS
    }

    public function setPEMCertificate(cert:String, key:String = null):Void {
        if (key == null) key = cert;
        certificate = PEM.readCertIntoArray(cert);
        privateKey = PEM.readRSAPrivateKey(key);
    }
}
