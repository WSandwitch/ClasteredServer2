/**
 * SSLEvent
 * 
 * This is used by TLSEngine to let the application layer know
 * when we're ready for sending, or have received application data
 * This Event was created by Bobby Parker to support SSL 3.0.
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;


import com.hurlant.util.Event;
import com.hurlant.util.ByteArray;

class SSLEvent extends Event {
    public static inline var DATA = "data";
    public static inline var READY = "ready";

    public var data:ByteArray;

    public function new(type:String, data:ByteArray = null) {
        this.data = data;
        super(type, false, false);
    }
}
