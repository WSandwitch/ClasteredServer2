package com.hurlant.crypto.tls;
import com.hurlant.crypto.tls.SSLConnectionState;

class ConnectionStateRW {
    public var read:IConnectionState;
    public var write:IConnectionState;

    public function new(read:IConnectionState, write:IConnectionState) {
        this.read = read;
        this.write = write;
    }
}