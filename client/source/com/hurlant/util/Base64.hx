/*
 * Copyright (C) 2012 Jean-Philippe Auclair
 * Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 * Base64 library for ActionScript 3.0.
 * By: Jean-Philippe Auclair : http://jpauclair.net
 * Based on article: http://jpauclair.net/2010/01/09/base64-optimized-as3-lib/
 * Benchmark:
 * This version: encode: 260ms decode: 255ms
 * Blog version: encode: 322ms decode: 694ms
 * as3Crypto encode: 6728ms decode: 4098ms
 *
 * Encode: com.sociodox.utils.Base64 is 25.8x faster than as3Crypto Base64
 * Decode: com.sociodox.utils.Base64 is 16x faster than as3Crypto Base64
 *
 * Optimize & Profile any Flash content with TheMiner ( http://www.sociodox.com/theminer )
 */
package com.hurlant.util;


import haxe.Int32;
import com.hurlant.util.ByteArray;

class Base64
{
    
    private static var _encodeChars : Array<Int32> = _initEncoreChar();
    private static var _decodeChars : Array<Int32> = _initDecodeChar();
    
    public static function encode(data : String) : String{
        var bytes : ByteArray = new ByteArray();
        bytes.writeUTFBytes(data);
        return encodeByteArray(bytes);
    }
    
    public static function decode(data : String) : String{
        var bytes : ByteArray = decodeToByteArray(data);
        return bytes.readUTFBytes(bytes.length);
    }
    
    public static function encodeByteArray(data : ByteArray) : String{
        var out : ByteArray = new ByteArray();
        //Presetting the length keep the memory smaller and optimize speed since there is no "grow" needed
        out.length = Std.int((2 + data.length - ((data.length + 2) % 3)) * 4 / 3);  //Preset length //1.6 to 1.5 ms
        var i : Int32 = 0;
        var r : Int32 = data.length % 3;
        var len : Int32 = data.length - r;
        var c : Int32;  //read (3) character AND write (4) characters
        var outPos : Int32 = 0;
        while (i < len){
            //Read 3 Characters (8bit * 3 = 24 bits)
            c = data[(i++)] << 16 | data[(i++)] << 8 | data[(i++)];
            
            out[(outPos++)] = _encodeChars[(c >>> 18)];
            out[(outPos++)] = _encodeChars[(c >>> 12 & 0x3f)];
            out[(outPos++)] = _encodeChars[(c >>> 6 & 0x3f)];
            out[(outPos++)] = _encodeChars[(c & 0x3f)];
        }  //Need two "=" padding  
        
        
        
        if (r == 1) {
            //Read one char, write two chars, write padding
            c = data[i];
            
            out[(outPos++)] = _encodeChars[(c >>> 2)];
            out[(outPos++)] = _encodeChars[((c & 0x03) << 4)];
            out[(outPos++)] = 61;
            out[(outPos++)] = 61;
        }
        //Need one "=" padding
        else if (r == 2) {
            c = data[(i++)] << 8 | data[(i)];
            
            out[(outPos++)] = _encodeChars[(c >>> 10)];
            out[(outPos++)] = _encodeChars[(c >>> 4 & 0x3f)];
            out[(outPos++)] = _encodeChars[((c & 0x0f) << 2)];
            out[(outPos++)] = 61;
        }
        
        return out.readUTFBytes(out.length);
    }
    
    public static function decodeToByteArray(str : String) : ByteArray{
        var c1 : Int32;
        var c2 : Int32;
        var c3 : Int32;
        var c4 : Int32;
        var i : Int32 = 0;
        var len : Int32 = str.length;
        
        var byteString : ByteArray = new ByteArray();
        byteString.writeUTFBytes(str);
        var outPos : Int32 = 0;
        while (i < len){
            //c1
            c1 = _decodeChars[(byteString[i++])];
            if (c1 == -1) 
                break;  //c2
            
            
            
            c2 = _decodeChars[(byteString[i++])];
            if (c2 == -1) 
                break;
            
            byteString[(outPos++)] = (c1 << 2) | ((c2 & 0x30) >> 4);
            
            //c3
            c3 = byteString[(i++)];
            if (c3 == 61) 
                break;
            
            c3 = _decodeChars[(c3)];
            if (c3 == -1) 
                break;
            
            byteString[(outPos++)] = ((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2);
            
            //c4
            c4 = byteString[(i++)];
            if (c4 == 61) 
                break;
            
            c4 = _decodeChars[(c4)];
            if (c4 == -1) 
                break;
            
            byteString[(outPos++)] = ((c3 & 0x03) << 6) | c4;
        }
        byteString.length = outPos;
        byteString.position = 0;
        return byteString;
    }
    
    @:meta(Deprecated())

    public static function decodeToByteArrayB(str : String) : ByteArray{
        return decodeToByteArray(str);
    }
    
    private static function _initEncoreChar() : Array<Int32>{
        var encodeChars : Array<Int32> = new Array<Int32>();
        
        // We could push the number directly
        // but I think it's nice to see the characters (with no overhead on encode/decode)
        var chars : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        for (i in 0...64){
            encodeChars[i] = chars.charCodeAt(i);
        }
        
        return encodeChars;
    }
    
    private static function _initDecodeChar() : Array<Int32>{
        var decodeChars : Array<Int32> = [
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, 
                -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 
                15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, 
                -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 
                41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
        
        return decodeChars;
    }

    public function new()
    {
    }
}


