/**
 * Memory
 * 
 * A class with a few memory-management methods, as much as 
 * such a thing exists in a Flash player.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util;

import haxe.Int32;

class Memory {
    public static var used(get, never):Int32;

    public static function gc():Void {
    }

    private static function get_used():Int32 {
        //return System.totalMemory;
        return 0;
    }
}
