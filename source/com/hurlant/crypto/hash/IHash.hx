/**
 * IHash
 * 
 * An interface for each hash function to implement
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.hash;


import haxe.Int32;
import com.hurlant.util.ByteArray;

interface IHash {
    function getInputSize():Int32;
    function getHashSize():Int32;
    function hash(src:ByteArray):ByteArray;
    function toString():String;
    function getPadSize():Int32;
}
