/**
 * IConnectionState
 * 
 * Interface for TLS/SSL Connection states.
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.tls;

import haxe.Int32;
import com.hurlant.util.ByteArray;

interface IConnectionState {
    function decrypt(type:Int32, length:Int32, p:ByteArray):ByteArray;
    function encrypt(type:Int32, p:ByteArray):ByteArray;
}
