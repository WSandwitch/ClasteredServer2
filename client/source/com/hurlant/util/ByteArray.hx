package com.hurlant.util;

import com.hurlant.crypto.encoding.binary.BinaryEncodings;
import com.hurlant.crypto.encoding.Charsets;
import haxe.Int32;
import haxe.io.Bytes;

abstract ByteArray(ByteArrayData) to ByteArrayData from ByteArrayData {
    public var position(get, set):Int32;
    public var length(get, set):Int32;
    public var bytesAvailable(get, never):Int32;
    public var endian(get, set):Endian;

    public function new() { this = new ByteArrayData(); }

    @:from static public function fromBytes(bytes:Bytes):ByteArray {
        var out = new ByteArrayData(Bytes.alloc(bytes.length));
        out._data.blit(0, bytes, 0, bytes.length);
        return out;
    }

    static public function fromBytesArray(bytes:Array<Int32>):ByteArray {
        var out = new ByteArrayData(Bytes.alloc(bytes.length));
        var data = out._data;
        for (n in 0 ... bytes.length) data.set(n, bytes[n]);
        return out;
    }

    static public function fromInt32ArrayBE(ints:Array<Int32>):ByteArray {
        var out = new ByteArrayData(Bytes.alloc(ints.length * 4));
        out.endian = Endian.BIG_ENDIAN;
        for (i in ints) out.writeUnsignedInt(i);
        return out;
    }

    static public function fromInt32ArrayLE(ints:Array<Int32>):ByteArray {
        var out = new ByteArrayData(Bytes.alloc(ints.length * 4));
        out.endian = Endian.LITTLE_ENDIAN;
        for (i in ints) out.writeUnsignedInt(i);
        return out;
    }

    static public function cloneBytes(v:Bytes, offset:Int = 0, length:Int = -1):Bytes {
        if (length < 0) length = v.length;
        var out = Bytes.alloc(length);
        out.blit(0, v, offset, length);
        return out;
    }

    @:to public function getBytes():Bytes { return cloneBytes(this.getBytes(), 0, this.length); }
    public function toBytesArray():Array<Int32> {
        return [for (n in 0 ... length) get(n)];
    }

    public function toInt32ArrayLE():Array<Int32> {
        var t = clone();
        t.endian = Endian.LITTLE_ENDIAN;
        t.position = 0;
        return [for (n in 0 ... Std.int(length / 4)) readUnsignedInt()];
    }

    public function toInt32ArrayBE():Array<Int32> {
        var t = clone();
        t.endian = Endian.BIG_ENDIAN;
        t.position = 0;
        return [for (n in 0 ... Std.int(length / 4)) readUnsignedInt()];
    }

    public function readBoolean():Bool { return this.readUnsignedByte() != 0; }
    public function readByte():Int32 { return this.readByte(); }
    public function readUnsignedByte():Int32 { return this.readUnsignedByte(); }
    public function readShort():Int32 { return this.readShort(); }
    public function readUnsignedShort():Int32 { return this.readUnsignedShort(); }
    public function readUnsignedInt():Int32 { return this.readUnsignedInt(); }
    public function readBytes(output:ByteArray, offset:Int32, length:Int32) { return this.readBytes(output, offset, length); }
    public function readBytes2(length:Int32):Bytes { return this.readBytes2(length); }
    public function readMultiByte(length:Int32, encoding:String):String { return this.readMultiByte(length, encoding); }
    public function readUTFBytes(length:Int32):String { return this.readUTFBytes(length); }

    public function writeByte(value:Int32) { return this.writeByte(value); }
    public function writeUnsignedByte(value:Int32) { return this.writeUnsignedByte(value); }
    public function writeShort(value:Int32) { return this.writeShort(value); }
    public function writeInt24(value:Int32) { return this.writeInt24(value); }
    public function writeUnsignedInt(value:Int32) { return this.writeUnsignedInt(value); }
    public function writeBytes(input:ByteArray, offset:Int32 = 0, length:Int32 = 0) { return this.writeBytes(input, offset, length); }
    public function writeBytes2(input:Bytes) { return this.writeBytes2(input); }
    public function writeMultiByte(str:String, encoding:String) { return this.writeMultiByte(str, encoding); }
    public function writeUTFBytes(str:String) { return this.writeUTFBytes(str); }
    public function writeUTF(str:String) { return this.writeUTF(str); }

    private function get_endian():Endian { return this.endian; }
    private function get_position():Int32 { return this.position; }
    private function get_length():Int32 { return this.length; }
    private function get_bytesAvailable():Int32 { return this.bytesAvailable; }
    private function set_endian(value:Endian):Endian { return this.endian = value; }
    private function set_position(value:Int32):Int32 { return this.position = value; }
    private function set_length(value:Int32):Int32 { return this.length = value; }

    public function clone():ByteArray {
        var out = new ByteArray();
        out.writeBytes(this);
        out.position = 0;
        return out;
    }

    @:arrayAccess public function get(index:Int32):Int32 { return this.get(index); }
    @:arrayAccess public function set(index:Int32, value:Int32):Int32 { return this.set(index, value); }
}

class ByteArrayData implements IDataOutput implements IDataInput {
    public var position(get, set):Int32;
    public var length(get, set):Int32;
    public var bytesAvailable(get, never):Int32;
    public var endian:Endian = Endian.BIG_ENDIAN;
    //public var endian:Endian = Endian.LITTLE_ENDIAN;
    public var _data:Bytes = null;
    public var _length:Int32 = 0;
    public var _position:Int32 = 0;

    public function new(_data:Bytes = null, _position:Int = 0, _length:Int = -1) {
        if (_length < 0) _length = (_data != null) ? _data.length : 0;
        this._data = (_data != null) ? _data : Bytes.alloc(16);
        this._position = _position;
        this._length = _length;
    }

    private function ensureLength(elength:Int32) {
        var oldLength = this._length;
        this._length = Std.int(Math.max(this._length, elength));

        if (_data.length < this._length) {
            var newData = Bytes.alloc(Std.int(Math.max(_data.length * 2, this._length)));
            var oldData = _data;
            newData.blit(0, oldData, 0, oldLength);
            _data = newData;
        }
    }

    public function readBytes(output:ByteArray, offset:Int32, length:Int32) {
        if (length == 0) length = this.bytesAvailable;
        output.position = offset;
        for (n in 0 ... length) output.writeByte(this.readUnsignedByte());
    }

    public function readBytes2(length:Int32):Bytes {
        var out = new ByteArray();
        readBytes(out, 0, length);
        return out;
    }

    public function readUTFBytes(length:Int32):String {
        return readMultiByte(length, 'utf-8');
    }

    public function readMultiByte(length:Int32, encoding:String):String {
        return Charsets.fromString(encoding).decode(readBytes2(length));
    }

    public function readByte():Int32 {
        return Std2.sx8(readUnsignedByte());
    }

    public function readShort():Int32 {
        return Std2.sx16(readUnsignedShort());
    }

    public function readUnsignedByte():Int32 {
        ensureWrite(1);
        var result = get(this._position) & 0xFF;
        this._position += 1;
        return result;
    }

    public function readUnsignedShort():Int32 {
        ensureWrite(2);
        var result = bswap16Endian(this._data.getUInt16(this.position));
        this._position += 2;
        return result;
    }

    public function readUnsignedInt():Int32 {
        ensureWrite(4);
        var result = bswap32Endian(this._data.getInt32(this.position));
        this._position += 4;
        return result;
    }

    public function set(index:Int32, value:Int32):Int32 {
        ensureLength(index + 1);
        this._data.set(index, value);
        return value;
    }

    public function get(index:Int32):Int32 {
        ensureLength(index + 1);
        return this._data.get(index) & 0xFF;
    }

    public function writeUTF(str:String) {
        this.writeUnsignedShort(str.length);
        this.writeUTFBytes(str);
    }

    public function writeUTFBytes(str:String) {
        return writeMultiByte(str, 'utf-8');
    }

    public function writeMultiByte(str:String, encoding:String) {
        writeBytes(Charsets.fromString(encoding).encode(str));
    }

    public function writeByte(value:Int32) {
        writeUnsignedByte(value);
    }

    public function writeShort(value:Int32) {
        writeUnsignedShort(value);
    }

    public function writeInt24(value:Int32) {
        writeUnsignedInt24(value);
    }

    public function writeBytes(input:ByteArray, offset:Int32 = 0, length:Int32 = 0) {
        if (length == 0) length = input.length - offset;
        //throw new Error('Not implemented');
        for (n in 0 ... length) {
            this.writeByte(input[offset + n]);
        }
        //this.position = 0;
    }

    public function writeBytes2(input:Bytes) {
        this.writeBytes(input);
    }

    public function writeUnsignedByte(value:Int32) {
        ensureWrite(1);
        this._data.set(this._position, value);
        this._position += 1;
    }

    public function writeUnsignedShort(value:Int32) {
        ensureWrite(2);
        this._data.setUInt16(this._position, bswap16Endian(value));
        this._position += 2;
    }

    public function writeUnsignedInt24(value:Int32) {
        var v2 = bswap24Endian(value);
        writeByte((v2 >>> 0) & 0xFF);
        writeByte((v2 >>> 8) & 0xFF);
        writeByte((v2 >>> 16) & 0xFF);
    }

    public function writeUnsignedInt(value:Int32) {
        ensureWrite(4);
        this._data.setInt32(this._position, bswap32Endian(value));
        this._position += 4;
    }

    private function get_position():Int32 {
        return this._position;
    }

    private function get_length():Int32 {
        return this._length;
    }

    private function set_position(value:Int32):Int32 {
        return _position = value;
    }

    private function set_length(value:Int32):Int32 {
        ensureLength(value);
        if (this._position > value) this._position = value;
        return this._length = value;
    }

    private function get_bytesAvailable():Int32 {
        return this.length - this.position;
    }

    private function ensureWrite(count:Int32) {
        ensureLength(this._position + count);
    }

    private function bswap32Endian(value:Int32):Int32 {
        return (this.endian == Endian.BIG_ENDIAN) ? Std2.bswap32(value) : value;
    }

    private function bswap24Endian(value:Int32):Int32 {
        return (this.endian == Endian.BIG_ENDIAN) ? Std2.bswap24(value) : value;
    }

    private function bswap16Endian(value:Int32):Int32 {
        return (this.endian == Endian.BIG_ENDIAN) ? Std2.bswap16(value) : value;
    }

    public function getBytes():Bytes {
        var out = Bytes.alloc(length);
        out.blit(0, this._data, 0, length);
        return out;
    }
}
