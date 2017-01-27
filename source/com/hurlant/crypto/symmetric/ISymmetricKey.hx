/**
 * ISymmetricKey
 * 
 * An interface for symmetric encryption keys to implement.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric;


import com.hurlant.util.ByteArray;

interface ISymmetricKey {
    /**
     * Returns the block size used by this particular encryption algorithm
     */
    function getBlockSize():Int;

    /**
     * Encrypt one block of data in "block", starting at "index", of length "getBlockSize()"
     */
    function encrypt(block:ByteArray, index:Int = 0):Void;

    /**
     * Decrypt one block of data in "block", starting at "index", of length "getBlockSize()"
     */
    function decrypt(block:ByteArray, index:Int = 0):Void;

    /**
     * Attempts to destroy sensitive information from memory, such as encryption keys.
     * Note: This is not guaranteed to work given the Flash sandbox model.
     */
    function dispose():Void;

    function toString():String;
}
