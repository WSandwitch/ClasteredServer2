/**
 * TLSEvent
 * 
 * This is used by TLSEngine to let the application layer know
 * when we're ready for sending, or have received application data
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import com.hurlant.util.Event;
import com.hurlant.crypto.cert.X509Certificate;

class TLSSocketEvent extends Event {
    public static inline var PROMPT_ACCEPT_CERT = "promptAcceptCert";

    public var cert:X509Certificate;

    public function new(cert:X509Certificate = null) {
        super(PROMPT_ACCEPT_CERT, false, false);
        this.cert = cert;
    }
}
