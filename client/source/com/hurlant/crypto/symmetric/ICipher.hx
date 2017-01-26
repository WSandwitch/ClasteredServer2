/**
 * ICipher
 * 
 * A generic interface to use symmetric ciphers
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric;


import com.hurlant.util.ByteArray;

interface ICipher {
    function getBlockSize():Int;
    function encrypt(src:ByteArray):Void;
    function decrypt(src:ByteArray):Void;
    function dispose():Void;
    function toString():String;
}
