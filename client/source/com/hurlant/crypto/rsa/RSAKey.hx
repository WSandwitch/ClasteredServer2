/**
 * RSAKey
 * 
 * An ActionScript 3 implementation of RSA + PKCS#1 (light version)
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The jsbn library, Copyright (c) 2003-2005 Tom Wu
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.rsa;

import haxe.Int32;
import com.hurlant.crypto.tls.TLSError;
import com.hurlant.util.Std2;
import com.hurlant.crypto.prng.Random;
import com.hurlant.math.BigInteger;
import com.hurlant.util.Memory;

import com.hurlant.util.ByteArray;

/**
 * Current limitations:
 * exponent must be smaller than 2^31.
 */
class RSAKey {
    // public key
    public var e:Int32; // public exponent. must be <2^31
    public var n:BigInteger; // modulus
    // private key
    public var d:BigInteger;
    // extended private key
    public var p:BigInteger;
    public var q:BigInteger;
    public var dmp1:BigInteger;
    public var dmq1:BigInteger;
    public var coeff:BigInteger;
    // flags. flags are cool.
    private var canDecrypt:Bool;
    private var canEncrypt:Bool;

    public function new(
        N:BigInteger,
        E:Int32,
        D:BigInteger = null,
        P:BigInteger = null,
        Q:BigInteger = null,
        DP:BigInteger = null,
        DQ:BigInteger = null,
        C:BigInteger = null
    ) {
        this.n = N;
        this.e = E;
        this.d = D;
        this.p = P;
        this.q = Q;
        this.dmp1 = DP;
        this.dmq1 = DQ;
        this.coeff = C;

        // adjust a few flags.
        canEncrypt = (n != null && e != 0);
        canDecrypt = (canEncrypt && d != null);
    }

    public static function parsePublicKey(N:String, E:String):RSAKey {
        return new RSAKey(new BigInteger(N, 16, true), Std2.parseInt(E, 16));
    }

    public static function parsePrivateKey(
        N:String,
        E:String,
        D:String,
        P:String = null,
        Q:String = null,
        DMP1:String = null,
        DMQ1:String = null,
        IQMP:String = null
    ):RSAKey {
        if (P == null) {
            return new RSAKey(
                new BigInteger(N, 16, true), Std2.parseInt(E, 16), new BigInteger(D, 16, true)
            );
        } else {
            return new RSAKey(
                new BigInteger(N, 16, true), Std2.parseInt(E, 16), new BigInteger(D, 16, true),
                new BigInteger(P, 16, true), new BigInteger(Q, 16, true),
                new BigInteger(DMP1, 16, true), new BigInteger(DMQ1, 16, true),
                new BigInteger(IQMP, 16, true)
            );
        }
    }

    public function getBlockSize():Int32 {
        return Std.int((n.bitLength() + 7) / 8);
    }

    public function dispose():Void {
        e = 0;
        n.dispose();
        n = null;
        Memory.gc();
    }

    public function encrypt(src:ByteArray, dst:ByteArray, length:Int32, pad:ByteArray -> Int32 -> Int32 -> Int32 -> ByteArray = null):Void {
        _encrypt(doPublic, src, dst, length, pad, 0x02);
    }

    public function decrypt(src:ByteArray, dst:ByteArray, length:Int32, pad:BigInteger -> Int32 -> Int32 -> ByteArray = null):Void {
        _decrypt(doPrivate2, src, dst, length, pad, 0x02);
    }

    public function sign(src:ByteArray, dst:ByteArray, length:Int32, pad:ByteArray -> Int32 -> Int32 -> Int32 -> ByteArray = null):Void {
        _encrypt(doPrivate2, src, dst, length, pad, 0x01);
    }

    public function verify(src:ByteArray, dst:ByteArray, length:Int32, pad:BigInteger -> Int32 -> Int32 -> ByteArray = null):Void {
        _decrypt(doPublic, src, dst, length, pad, 0x01);
    }

    private function _encrypt(op:BigInteger -> BigInteger, src:ByteArray, dst:ByteArray, length:Int32, pad:ByteArray -> Int32 -> Int32 -> Int32 -> ByteArray, padType:Int32):Void {
        // adjust pad if needed
        if (pad == null) pad = pkcs1pad; // convert src to BigInteger

        if (src.position >= src.length) {
            src.position = 0;
        }
        var bl:Int32 = getBlockSize();
        var end:Int32 = src.position + length;
        while (src.position < end) {
            var block = new BigInteger(pad(src, end, bl, padType), bl, true);
            var chunk = op(block);

            var b:Int32 = bl - Math.ceil(chunk.bitLength() / 8);
            while (b > 0) {
                dst.writeByte(0x00);
                --b;
            }

            chunk.toArray(dst);
        }
    }

    private function _decrypt(op:BigInteger -> BigInteger, src:ByteArray, dst:ByteArray, length:Int32, pad:BigInteger -> Int32 -> Int32 -> ByteArray, padType:Int32):Void {
        // adjust pad if needed
        // src:BigInteger, n:Int32, type:Int32 = 0x02
        if (pad == null) {// convert src to BigInteger
            //trace('****************** pkcs1unpad');
            pad = pkcs1unpad;
        }

        if (src.position >= src.length) {
            src.position = 0;
        }
        var bl = getBlockSize();
        var end = src.position + length;
        while (src.position < end) {
            var block = new BigInteger(src, bl, true);
            var chunk = op(block);
            var b = pad(chunk, bl, padType);
            if (b == null) throw new TLSError("Decrypt error - padding function returned null!", TLSError.decode_error);

            dst.writeBytes(b);
        }
    }

    /**
     * PKCS#1 pad. type 1 (0xff) or 2, random.
     * puts as much data from src into it, leaves what doesn't fit alone.
     */

    private function pkcs1pad(src:ByteArray, end:Int32, n:Int32, type:Int32 = 0x02):ByteArray {
        var out = new ByteArray();
        var p = src.position;
        end = Std.int(Std2.min3(end, src.length, p + n - 11));
        src.position = end;
        var i = end - 1;
        while (i >= p && n > 11) out[--n] = src[i--];
        out[--n] = 0;
        if (type == 0x02) { // type 2
            var rng = new Random();
            var x = 0;
            while (n > 2) {
                do { x = rng.nextByte(); } while ((x == 0));
                out[--n] = x;
            }
        } else { // type 1
            while (n > 2) out[--n] = 0xFF;
        }
        out[--n] = type;
        out[--n] = 0;
        return out;
    }

    /**
     *
     * @param src
     * @param n
     * @param type Not used.
     * @return
     *
     */
    private function pkcs1unpad(src:BigInteger, n:Int32, type:Int32 = 0x02):ByteArray {
        var out = new ByteArray();
        var b = new ByteArray();
        src.toArray(b);

        b.position = 0;
        var i = 0;
        while (i < b.length && b[i] == 0) ++i;

        if (b.length - i != n - 1 || b[i] != type) {
            trace("PKCS#1 unpad: i=" + i + ", expected b[i]==" + type + ", got b[i]=${b[i]}");
            return null;
        }
        ++i;
        while (b[i] != 0) {
            if (++i >= b.length) {
                trace("PKCS#1 unpad: i=" + i + ", b[i-1]!=0 (=" + Std.string(b[i - 1]) + ")");
                return null;
            }
        }
        while (++i < b.length) {
            out.writeByte(b[i]);
        }
        out.position = 0;
        return out;
    }

    /**
     * Raw pad.
     */
    public function rawpad(src:ByteArray, end:Int32, n:Int32, type:Int32 = 0):ByteArray {
        return src;
    }

    public function rawunpad(src:BigInteger, n:Int32, type:Int32 = 0):ByteArray {
        return src.toByteArray();
    }

    public function toString():String {
        return "rsa";
    }

    public function dump():String {
        var s:String = "N=" + Std.string(n) + "\n" +
        "E=" + Std.string(e) + "\n";
        if (canDecrypt) {
            s += "D=" + Std.string(d) + "\n";
            if (p != null && q != null) {
                s += "P=" + Std.string(p) + "\n";
                s += "Q=" + Std.string(q) + "\n";
                s += "DMP1=" + Std.string(dmp1) + "\n";
                s += "DMQ1=" + Std.string(dmq1) + "\n";
                s += "IQMP=" + Std.string(coeff) + "\n";
            }
        }
        return s;
    }


    /**
     * note: We should have a "nice" variant of this function that takes a callback,
     * 		and perform the computation is small fragments, to keep the web browser
     * 		usable.
     *
     * @param B
     * @param E
     * @return a new random private key B bits long, using public expt E
     *
     */
    public static function generate(B:Int32, E:String):RSAKey {
        var rng = new Random();
        var qs = B >> 1;
        var key = new RSAKey(null, 0, null);
        key.e = Std2.parseInt(E, 16);
        var ee = new BigInteger(E, 16, true);
        while (true) {
            while (true) {
                key.p = bigRandom(B - qs, rng);
                if (key.p.subtract(BigInteger.ONE).gcd(ee).compareTo(BigInteger.ONE) == 0 &&
                key.p.isProbablePrime(10)) break;
            }
            while (true) {
                key.q = bigRandom(qs, rng);
                if (key.q.subtract(BigInteger.ONE).gcd(ee).compareTo(BigInteger.ONE) == 0 &&
                key.q.isProbablePrime(10)) break;
            }
            if (key.p.compareTo(key.q) <= 0) {
                var t = key.p;
                key.p = key.q;
                key.q = t;
            }
            var p1 = key.p.subtract(BigInteger.ONE);
            var q1 = key.q.subtract(BigInteger.ONE);
            var phi = p1.multiply(q1);
            if (phi.gcd(ee).compareTo(BigInteger.ONE) == 0) {
                key.n = key.p.multiply(key.q);
                key.d = ee.modInverse(phi);
                key.dmp1 = key.d.mod(p1);
                key.dmq1 = key.d.mod(q1);
                key.coeff = key.q.modInverse(key.p);
                break;
            }
        }
        key.canEncrypt = (key.n != null && key.e != 0);
        key.canDecrypt = (key.canEncrypt && key.d != null);
        return key;
    }

    private static function bigRandom(bits:Int32, rnd:Random):BigInteger {
        if (bits < 2) return BigInteger.nbv(1);
        var x = new ByteArray();
        rnd.nextBytes(x, (bits >> 3));
        x.position = 0;
        var b = new BigInteger(x, 0, true);
        b.primify(bits, 1);
        return b;
    }

    private function doPublic(x:BigInteger):BigInteger {
        return x.modPowInt(e, n);
    }

    private function doPrivate2(x:BigInteger):BigInteger {
        if (p == null && q == null) {
            return x.modPow(d, n);
        }

        var xp = x.mod(p).modPow(dmp1, p);
        var xq = x.mod(q).modPow(dmq1, q);

        while (xp.compareTo(xq) < 0) xp = xp.add(p);
        var r = xp.subtract(xq).multiply(coeff).mod(p).multiply(q).add(xq);

        return r;
    }

    private function doPrivate(x:BigInteger):BigInteger {
        if (p == null || q == null) return x.modPow(d, n);
        // TODO: re-calculate any missing CRT params

        var xp = x.mod(p).modPow(dmp1, p);
        var xq = x.mod(q).modPow(dmq1, q);

        while (xp.compareTo(xq) < 0) xp = xp.add(p);
        return xp.subtract(xq).multiply(coeff).mod(p).multiply(q).add(xq);
    }
}
