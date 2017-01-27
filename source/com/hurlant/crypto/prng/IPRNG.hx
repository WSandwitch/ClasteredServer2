/**
 * IPRNG
 * 
 * An interface for classes that can be used a pseudo-random number generators
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.prng;


import haxe.Int32;
import com.hurlant.util.ByteArray;

interface IPRNG {
    function getPoolSize():Int32;
    function init(key:ByteArray):Void;
    function next():Int32;
    function dispose():Void;
    function toString():String;
}
