/**
 * IAsn1Type
 * 
 * An interface for Asn-1 types.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util.der;


import haxe.Int32;
import com.hurlant.util.ByteArray;

interface IAsn1Type {
    function getType():Int32;
    function getLength():Int32;
    function toDER():ByteArray;
}