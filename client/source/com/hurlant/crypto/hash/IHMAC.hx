/**
 * HMAC
 * 
 * An ActionScript 3 interface for HMAC & MAC 
 * implementations.
 * 
 * Loosely copyrighted by Bobby Parker
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.hash;


import haxe.Int32;
import com.hurlant.util.ByteArray;

interface IHMAC {

    function getHashSize():Int32;
    /**
     * Compute a HMAC using a key and some data.
     * It doesn't modify either, and returns a new ByteArray with the HMAC value.
     */
    function compute(key:ByteArray, data:ByteArray):ByteArray;
    function dispose():Void;
    function toString():String;
}
