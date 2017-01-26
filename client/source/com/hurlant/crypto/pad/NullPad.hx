/**
 * NullPad
 * 
 * A padding class that doesn't pad.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.pad;


import com.hurlant.crypto.pad.IPad;
import haxe.Int32;
import com.hurlant.util.ByteArray;

/**
 * A pad that does nothing.
 * Useful when you don't want padding in your Mode.
 */
class NullPad implements IPad {
    public function new() {
    }

    public function unpad(a:ByteArray):Void {
        return;
    }

    public function pad(a:ByteArray):Void {
        return;
    }

    public function setBlockSize(bs:Int32):Void {
        return;
    }
}
