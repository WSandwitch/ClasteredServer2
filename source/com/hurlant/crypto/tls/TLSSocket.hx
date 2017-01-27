/**
 * TLSSocket
 * 
 * This is the "end-user" TLS class.
 * It works just like a Socket, by encapsulating a Socket and
 * wrapping the TLS protocol around the data that passes over it.
 * This class can either create a socket connection, or reuse an
 * existing connected socket. The later is useful for STARTTLS flows.
 * 
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;

import com.hurlant.util.Error;


import com.hurlant.util.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.ObjectEncoding;
import flash.net.Socket;
import com.hurlant.util.ByteArray;
import flash.utils.Endian;
import flash.utils.IDataInput;
import flash.utils.IDataOutput;
import flash.utils.ClearTimeout;
import flash.utils.SetTimeout;
import com.hurlant.crypto.cert.X509Certificate;

@:meta(Event(name = "close", type = "flash.events.Event"))
@:meta(Event(name = "connect", type = "flash.events.Event"))
@:meta(Event(name = "ioError", type = "flash.events.IOErrorEvent"))
@:meta(Event(name = "securityError", type = "flash.events.SecurityErrorEvent"))
@:meta(Event(name = "socketData", type = "flash.events.ProgressEvent"))
@:meta(Event(name = "acceptPeerCertificatePrompt", type = "flash.events.Event"))

/**
 * It feels like a socket, but it wraps the stream
 * over TLS 1.0
 *
 * That's all.
 *
 */
class TLSSocket extends Socket implements IDataInput implements IDataOutput {

    private var _endian:String;
    private var _objectEncoding:Int;

    private var _iStream:ByteArray;
    private var _oStream:ByteArray;
    private var _iStream_cursor:Int;

    private var _socket:Socket;
    private var _config:TLSConfig;
    private var _engine:TLSEngine;
    public static inline var ACCEPT_PEER_CERT_PROMPT:String = "acceptPeerCertificatePrompt";

    public function new(host:String = null, port:Int = 0, config:TLSConfig = null) {
        super();
        _config = config;
        if (host != null && port != 0) {
            connect(host, port);
        }
    }

    override private function get_BytesAvailable():Int {
        return _iStream.bytesAvailable;
    }

    override private function get_Connected():Bool {
        return _socket.connected;
    }

    override private function get_Endian():String {
        return _endian;
    }

    override private function set_Endian(value:String):String {
        _endian = value;
        _iStream.endian = value;
        _oStream.endian = value;
        return value;
    }

    override private function get_ObjectEncoding():Int {
        return _objectEncoding;
    }

    override private function set_ObjectEncoding(value:Int):Int {
        _objectEncoding = value;
        _iStream.objectEncoding = value;
        _oStream.objectEncoding = value;
        return value;
    }


    private function onTLSData(event:TLSEvent):Void {
        if (_iStream.position == _iStream.length) {
            _iStream.position = 0;
            _iStream.length = 0;
            _iStream_cursor = 0;
        }
        var cursor:Int = _iStream.position;
        _iStream.position = _iStream_cursor;
        _iStream.writeBytes(event.data);
        _iStream_cursor = _iStream.position;
        _iStream.position = cursor;
        dispatchEvent(new ProgressEvent(ProgressEvent.SOCKET_DATA, false, false, event.data.length));
    }

    private function onTLSReady(event:TLSEvent):Void {
        _ready = true;
        scheduleWrite();
    }

    private function onTLSClose(event:Event):Void {
        dispatchEvent(event);
        // trace("Received TLS close");
        close();
    }

    private var _ready:Bool;
    private var _writeScheduler:Int;

    private function scheduleWrite():Void {
        if (_writeScheduler != 0) return;
        _writeScheduler = setTimeout(commitWrite, 0);
    }

    private function commitWrite():Void {
        clearTimeout(_writeScheduler);
        _writeScheduler = 0;
        if (_ready) {
            _engine.sendApplicationData(_oStream);
            _oStream.length = 0;
        }
    }


    override public function close():Void {
        _ready = false;
        _engine.close();
        if (_socket.connected) {
            _socket.flush();
            _socket.close();
        }
    }

    public function setTLSConfig(config:TLSConfig):Void {
        _config = config;
    }

    override public function connect(host:String, port:Int):Void {
        init(new Socket(), _config, host);
        _socket.connect(host, port);
        _engine.start();
    }

    public function releaseSocket():Void {
        _socket.removeEventListener(Event.CONNECT, dispatchEvent);
        _socket.removeEventListener(IOErrorEvent.IO_ERROR, dispatchEvent);
        _socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, dispatchEvent);
        _socket.removeEventListener(Event.CLOSE, dispatchEvent);
        _socket.removeEventListener(ProgressEvent.SOCKET_DATA, _engine.dataAvailable);
        _socket = null;
    }

    public function reinitialize(host:String, config:TLSConfig):Void {
        // Reinitialize the connection using new values
        // but re-use the existing socket
        // Doubt this is useful in any valid context other than my specific case (VMWare)
        var ba:ByteArray = new ByteArray();

        if (_socket.bytesAvailable > 0) {
            _socket.readBytes(ba, 0, _socket.bytesAvailable);
        } // Do nothing with it.

        _iStream = new ByteArray();
        _oStream = new ByteArray();
        _iStream_cursor = 0;
        objectEncoding = ObjectEncoding.DEFAULT;
        endian = Endian.BIG_ENDIAN;
        /* 
			_socket.addEventListener(Event.CONNECT, dispatchEvent);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, dispatchEvent);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, dispatchEvent);
			_socket.addEventListener(Event.CLOSE, dispatchEvent);
			*/

        if (config == null) {
            config = new TLSConfig(TLSEngine.CLIENT);
        }

        _engine = new TLSEngine(config, _socket, _socket, host);
        _engine.addEventListener(TLSEvent.DATA, onTLSData);
        _engine.addEventListener(TLSEvent.READY, onTLSReady);
        _engine.addEventListener(Event.CLOSE, onTLSClose);
        _engine.addEventListener(ProgressEvent.SOCKET_DATA, function(e:Dynamic):Void {_socket.flush();
        });
        _socket.addEventListener(ProgressEvent.SOCKET_DATA, _engine.dataAvailable);
        _engine.addEventListener(TLSEvent.PROMPT_ACCEPT_CERT, onAcceptCert);

        _ready = false;
        _engine.start();
    }

    public function startTLS(socket:Socket, host:String, config:TLSConfig = null):Void {
        if (!socket.connected) {
            throw new Error("Cannot STARTTLS on a socket that isn't connected.");
        }
        init(socket, config, host);
        _engine.start();
    }

    private function init(socket:Socket, config:TLSConfig, host:String):Void {
        _iStream = new ByteArray();
        _oStream = new ByteArray();
        _iStream_cursor = 0;
        objectEncoding = ObjectEncoding.DEFAULT;
        endian = Endian.BIG_ENDIAN;
        _socket = socket;
        _socket.addEventListener(Event.CONNECT, dispatchEvent);
        _socket.addEventListener(IOErrorEvent.IO_ERROR, dispatchEvent);
        _socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, dispatchEvent);
        _socket.addEventListener(Event.CLOSE, dispatchEvent);

        if (config == null) {
            config = new TLSConfig(TLSEngine.CLIENT);
        }
        _engine = new TLSEngine(config, _socket, _socket, host);
        _engine.addEventListener(TLSEvent.DATA, onTLSData);
        _engine.addEventListener(TLSEvent.PROMPT_ACCEPT_CERT, onAcceptCert);
        _engine.addEventListener(TLSEvent.READY, onTLSReady);
        _engine.addEventListener(Event.CLOSE, onTLSClose);
        _engine.addEventListener(ProgressEvent.SOCKET_DATA, function(e:Dynamic):Void {if (connected) _socket.flush();
        });
        _socket.addEventListener(ProgressEvent.SOCKET_DATA, _engine.dataAvailable);

        _ready = false;
    }

    override public function flush():Void {
        commitWrite();
        _socket.flush();
    }

    override public function readBoolean():Bool {
        return _iStream.readBoolean();
    }

    override public function readByte():Int {
        return _iStream.readByte();
    }

    override public function readBytes(bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
        _iStream.readBytes(bytes, offset, length);
    }

    override public function readDouble():Float {
        return _iStream.readDouble();
    }

    override public function readFloat():Float {
        return _iStream.readFloat();
    }

    override public function readInt():Int {
        return _iStream.readInt();
    }

    override public function readMultiByte(length:Int, charSet:String):String {
        return _iStream.readMultiByte(length, charSet);
    }

    override public function readObject():Dynamic {
        return _iStream.readObject();
    }

    override public function readShort():Int {
        return _iStream.readShort();
    }

    override public function readUnsignedByte():Int {
        return _iStream.readUnsignedByte();
    }

    override public function readUnsignedInt():Int {
        return _iStream.readUnsignedInt();
    }

    override public function readUnsignedShort():Int {
        return _iStream.readUnsignedShort();
    }

    override public function readUTF():String {
        return _iStream.readUTF();
    }

    override public function readUTFBytes(length:Int):String {
        return _iStream.readUTFBytes(length);
    }

    override public function writeBoolean(value:Bool):Void {
        _oStream.writeBoolean(value);
        scheduleWrite();
    }

    override public function writeByte(value:Int):Void {
        _oStream.writeByte(value);
        scheduleWrite();
    }

    override public function writeBytes(bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
        _oStream.writeBytes(bytes, offset, length);
        scheduleWrite();
    }

    override public function writeDouble(value:Float):Void {
        _oStream.writeDouble(value);
        scheduleWrite();
    }

    override public function writeFloat(value:Float):Void {
        _oStream.writeFloat(value);
        scheduleWrite();
    }

    override public function writeInt(value:Int):Void {
        _oStream.writeInt(value);
        scheduleWrite();
    }

    override public function writeMultiByte(value:String, charSet:String):Void {
        _oStream.writeMultiByte(value, charSet);
        scheduleWrite();
    }

    override public function writeObject(object:Dynamic):Void {
        _oStream.writeObject(object);
        scheduleWrite();
    }

    override public function writeShort(value:Int):Void {
        _oStream.writeShort(value);
        scheduleWrite();
    }

    override public function writeUnsignedInt(value:Int):Void {
        _oStream.writeUnsignedInt(value);
        scheduleWrite();
    }

    override public function writeUTF(value:String):Void {
        _oStream.writeUTF(value);
        scheduleWrite();
    }

    override public function writeUTFBytes(value:String):Void {
        _oStream.writeUTFBytes(value);
        scheduleWrite();
    }

    public function getPeerCertificate():X509Certificate {
        return _engine.peerCertificate;
    }

    public function onAcceptCert(event:TLSEvent):Void {
        dispatchEvent(new TLSSocketEvent(_engine.peerCertificate));
    }

    // These are just a passthroughs to the engine. Encapsulation, et al

    public function acceptPeerCertificate(event:Event):Void {
        _engine.acceptPeerCertificate();
    }

    public function rejectPeerCertificate(event:Event):Void {
        _engine.rejectPeerCertificate();
    }
}


