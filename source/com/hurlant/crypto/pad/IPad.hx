/**
 * IPad
 * 
 * An interface for padding mechanisms to implement.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.pad;


import haxe.Int32;
import com.hurlant.util.ByteArray;

/**
 * Tiny interface that represents a padding mechanism.
 */
interface IPad {
    /**
     * Add padding to the array
     */
    function pad(a:ByteArray):Void;

    /**
     * Remove padding from the array.
     * @throws Error if the padding is invalid.
     */
    function unpad(a:ByteArray):Void;

    /**
     * Set the blockSize to work on
     */
    function setBlockSize(bs:Int32):Void;
}
