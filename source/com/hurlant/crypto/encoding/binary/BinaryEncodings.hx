package com.hurlant.crypto.encoding.binary;

class BinaryEncodings {
    static public var BASE64(default, null):BinaryEncoding = new Base64();
    static public var BASE16(default, null):BinaryEncoding = new Base16();
    static public var HEX(default, null):BinaryEncoding = BASE16;

    static public function fromString(name:String):BinaryEncoding {
        return switch (name.toLowerCase()) {
            case "base16", "hex": BASE16;
            case "base64": BASE64;
            default: throw 'Unknown binary encoding $name';
        }
    }
}