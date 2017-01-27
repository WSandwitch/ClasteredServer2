/**
 * SimpleIVMode
 * 
 * A convenience class that automatically places the IV
 * at the beginning of the encrypted stream, so it doesn't have to
 * be handled explicitely.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric.mode;


import com.hurlant.crypto.symmetric.mode.IMode;
import com.hurlant.crypto.symmetric.mode.IVMode;
import haxe.Int32;
import com.hurlant.util.ByteArray;
import com.hurlant.util.Memory;

class SimpleIVMode implements IMode implements ICipher {
    private var mode:IVMode;
    private var cipher:ICipher;

    public function new(mode:IVMode) {
        this.mode = mode;
        cipher = cast(mode, ICipher);
    }

    public function getBlockSize():Int32 {
        return mode.getBlockSize();
    }

    public function dispose():Void {
        mode.dispose();
        mode = null;
        cipher = null;
        Memory.gc();
    }

    public function encrypt(src:ByteArray):Void {
        cipher.encrypt(src);
        var tmp:ByteArray = new ByteArray();
        tmp.writeBytes(mode.IV);
        tmp.writeBytes(src);
        src.position = 0;
        src.writeBytes(tmp);
    }

    public function decrypt(src:ByteArray):Void {
        var tmp:ByteArray = new ByteArray();
        tmp.writeBytes(src, 0, getBlockSize());
        mode.IV = tmp;
        tmp = new ByteArray();
        tmp.writeBytes(src, getBlockSize());
        cipher.decrypt(tmp);
        src.length = 0;
        src.writeBytes(tmp);
    }

    public function toString():String {
        return "simple-$cipher";
    }
}
