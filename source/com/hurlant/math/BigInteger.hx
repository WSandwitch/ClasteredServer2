/**
 * BigInteger
 * 
 * An ActionScript 3 implementation of BigInteger (light version)
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The jsbn library, Copyright (c) 2003-2005 Tom Wu
 * 
 * See LICENSE.txt for full license information.
 * 
 * Changes 2010-02-10 Jason von Nieda (jason[at]vonnieda.org)
 */
package com.hurlant.math;

import haxe.Int32;
import com.hurlant.util.Std2;
import com.hurlant.math.ClassicReduction;
import com.hurlant.math.IReduction;
import com.hurlant.math.MontgomeryReduction;
import com.hurlant.math.NullReduction;
import com.hurlant.util.Error;


import com.hurlant.crypto.prng.Random;
import com.hurlant.util.Hex;
import com.hurlant.util.Memory;

import com.hurlant.util.ByteArray;


class BigInteger {
    public static inline var DB = 28; // number of significant bits per chunk
    public static inline var DV = (1 << DB);
    public static inline var DM = (DV - 1); // Max value in a chunk

    public static inline var BI_FP:Int = 52;
    public static var FV:Float = Math.pow(2, BI_FP);
    public static var F1:Int = BI_FP - DB;
    public static var F2:Int = 2 * DB - BI_FP;

    public static var ZERO = nbv(0);
    public static var ONE = nbv(1);

    public var s:Int; // sign
    public var t:Int32; // number of chunks.
    public var a:Array<Int32>; // chunks

    /**
     *
     * @param value
     * @param radix  WARNING: If value is ByteArray, this holds the number of bytes to use.
     * @param unsigned
     *
     */

    public function new(value:Dynamic = null, radix:Int32 = 0, unsigned:Bool = false) {
        //trace('+++++++++++++ ' + value);
        a = new Array<Int>();
        if (Std.is(value, String)) {
            if (radix != 0 && radix != 16) {
                fromRadix(cast(value, String), radix);
                value = null;
            }
            else {
                value = Hex.toArray(value);
                radix = 0;
            }
        }

        if (value != null) {
            //if (Std.is(value, ByteArrayData)) {
            //trace(':::::::::::::: ' + value);
            var array = cast(value, ByteArray);
            var length:Int32 = radix;
            if (length == 0) length = (array.length - array.position);
            fromArray(array, length, unsigned);
        }
    }

    public function get(index:Int32):Int32 {
        return a[index];
    }

    public function set(index:Int32, value:Int32):Int32 {
        return a[index] = value;
    }

    public function dispose():Void {
        var r:Random = new Random();
        for (i in 0...a.length) {
            a[i] = cast r.nextByte();
        }
        a = null;
        t = 0;
        s = 0;
        Memory.gc();
    }

    public function toString(radix:Float = 16):String {
        if (s < 0) return "-" + negate().toString(radix);
        var k:Int32;
        switch (radix) {
            case 2: k = 1;
            case 4: k = 2;
            case 8: k = 3;
            case 16: k = 4;
            case 32: k = 5;
            default: return toRadix(Std.int(radix));
        }
        var km:Int32 = (1 << k) - 1;
        var d:Int32 = 0;
        var m:Bool = false;
        var r:String = "";
        var i:Int32 = t;
        var p:Int32 = DB - (i * DB) % k;
        if (i-- > 0) {
            if (p < DB && (d = a[i] >> p) > 0) {
                m = true;
                r = Std2.string(d, 36);
            }
            while (i >= 0) {
                if (p < k) {
                    d = (a[i] & ((1 << p) - 1)) << (k - p);
                    d |= a[--i] >>> (p += DB - k);
                }
                else {
                    d = (a[i] >> (p -= k)) & km;
                    if (p <= 0) {
                        p += DB;
                        --i;
                    }
                }
                if (d > 0) {
                    m = true;
                }
                if (m) {
                    r += Std2.string(d, 36);
                }
            }
        }
        return (m) ? r : "0";
    }

    public function toArray(array:ByteArray):Int32 {
        var k:Int32 = 8;
        var km:Int32 = (1 << k) - 1;
        var d:Int32 = 0;
        var i:Int32 = t;
        var p:Int32 = DB - (i * DB) % k;
        var m:Bool = false;
        var c:Int32 = 0;
        if (i-- > 0) {
            if (p < DB && (d = a[i] >> p) > 0) {
                m = true;
                array.writeByte(d);
                c++;
            }
            while (i >= 0) {
                if (p < k) {
                    d = (a[i] & ((1 << p) - 1)) << (k - p);
                    d |= a[--i] >> (p += DB - k);
                }
                else {
                    d = (a[i] >> (p -= k)) & km;
                    if (p <= 0) {
                        p += DB;
                        --i;
                    }
                }
                if (d > 0) {
                    m = true;
                }
                if (m) {
                    array.writeByte(d);
                    c++;
                }
            }
        }
        return c;
    }

    /**
     * best-effort attempt to fit into a Number.
     * precision can be lost if it just can't fit.
     */

    public function valueOf():Float {
        if (s == -1) return -negate().valueOf();
        var coef:Float = 1;
        var value:Float = 0;
        for (i in 0...t) {
            value += a[i] * coef;
            coef *= DV;
        }
        return value;
    }

    /**
     * -this
     */

    public function negate():BigInteger {
        var r:BigInteger = nbi();
        ZERO.subTo(this, r);
        return r;
    }

    /**
     * |this|
     */

    public function abs():BigInteger {
        return ((s < 0)) ? negate() : this;
    }

    /**
     * return + if this > v, - if this < v, 0 if equal
     */

    public function compareTo(v:BigInteger):Int32 {
        var r:Int32 = s - v.s;
        if (r != 0) {
            return r;
        }
        var i:Int32 = t;
        r = i - v.t;
        if (r != 0) {
            return ((s < 0)) ? r * -1 : r;
        }
        while (--i >= 0) {
            r = a[i] - v.a[i];
            if (r != 0) return r;
        }
        return 0;
    }

    /**
     * returns the number of bits in this
     */

    public function bitLength():Int {
        if (t <= 0) return 0;
        return DB * (t - 1) + Std2.nbits(cast a[t - 1] ^ (s & DM));
    }

    /**
     *
     * @param v
     * @return this % v
     *
     */

    public function mod(v:BigInteger):BigInteger {
        var r:BigInteger = nbi();
        abs().divRemTo(v, null, r);
        if (s < 0 && r.compareTo(ZERO) > 0) {
            v.subTo(r, r);
        }
        return r;
    }

    /**
     * this^e % m, 0 <= e < 2^32
     */

    public function modPowInt(e:Int, m:BigInteger):BigInteger {
        return exp(e, (e < 256 || m.isEven()) ? new ClassicReduction(m) : new MontgomeryReduction(m));
    }

    /**
     * copy this to r
     */

    public function copyTo(r:BigInteger):Void {
        var i:Int = t - 1;
        while (i >= 0) {
            r.a[i] = a[i];
            --i;
        }
        r.t = t;
        r.s = s;
    }

    public function copyFrom(r:BigInteger):BigInteger {
        r.copyTo(this);
        return this;
    }

    /**
     * set from integer value "value", -DV <= value < DV
     */

    public function fromInt(value:Int):BigInteger {
        if (value > 0) {
            a[0] = value;
            s = 0;
            t = 1;
        } else if (value < -1) {
            a[0] = value + DV;
            s = -1;
            t = 1;
        } else {
            t = 0;
            s = 0;
        }
        return this;
    }

    /**
     * set from ByteArray and length,
     * starting a current position
     * If length goes beyond the array, pad with zeroes.
     */
    public function fromArray(value:ByteArray, length:Int, unsigned:Bool = false):Void {
        var p:Int = value.position;
        var i:Int = p + length;
        var sh:Int = 0;
        var k:Int = 8;
        t = 0;
        s = 0;
        while (--i >= p) {
            var x:Int32 = i < (value.length) ? value[i] : 0;
            if (sh == 0) {
                a[t++] = x;
            } else if (sh + k > DB) {
                a[t - 1] |= (x & ((1 << (DB - sh)) - 1)) << sh;
                a[t++] = x >> (DB - sh);
            } else {
                a[t - 1] |= x << sh;
            }
            sh += k;
            if (sh >= DB) sh -= DB;
        }
        if (!unsigned && (value[0] & 0x80) == 0x80) {
            s = -1;
            if (sh > 0) a[t - 1] |= ((1 << (DB - sh)) - 1) << sh;
        }
        clamp();
        value.position = Std.int(Math.min(p + length, value.length));
    }

    /**
     * clamp off excess high words
     */

    public function clamp():Void {
        var c:Int = s & DM;
        while (t > 0 && a[t - 1] == c) --t;
    }

    /**
     * r = this << n*DB
     */

    public function dlShiftTo(n:Int, r:BigInteger):Void {
        var i:Int;
        i = t - 1;
        while (i >= 0) {
            r.a[i + n] = a[i];
            --i;
        }
        i = n - 1;
        while (i >= 0) {
            r.a[i] = 0;
            --i;
        }
        r.t = t + n;
        r.s = s;
    }

    /**
     * r = this >> n*DB
     */

    public function drShiftTo(n:Int, r:BigInteger):Void {
        for (i in n...t) r.a[i - n] = a[i];
        r.t = Std.int(Math.max(t - n, 0));
        r.s = s;
    }

    /**
     * r = this << n
     */

    public function lShiftTo(n:Int, r:BigInteger):Void {
        var bs = n % DB;
        var cbs = DB - bs;
        var bm = (1 << cbs) - 1;
        var ds = Std.int(n / DB);
        var c = (s << bs) & DM;
        var i;
        i = t - 1;
        while (i >= 0) {
            r.a[i + ds + 1] = (a[i] >> cbs) | c;
            c = (a[i] & bm) << bs;
            --i;
        }
        i = ds - 1;
        while (i >= 0) {
            r.a[i] = 0;
            --i;
        }
        r.a[ds] = c;
        r.t = t + ds + 1;
        r.s = s;
        r.clamp();
    }

    /**
     * r = this >> n
     */

    public function rShiftTo(n:Int, r:BigInteger):Void {
        r.s = s;
        var ds:Int = Std.int(n / DB);
        if (ds >= t) {
            r.t = 0;
            return;
        }
        var bs:Int = n % DB;
        var cbs:Int = DB - bs;
        var bm:Int = (1 << bs) - 1;
        r.a[0] = a[ds] >> bs;
        var i:Int;
        for (i in ds + 1...t) {
            r.a[i - ds - 1] |= (a[i] & bm) << cbs;
            r.a[i - ds] = a[i] >> bs;
        }
        if (bs > 0) r.a[t - ds - 1] |= (s & bm) << cbs;
        r.t = t - ds;
        r.clamp();
    }

    /**
     * r = this - v
     */

    public function subTo(v:BigInteger, r:BigInteger):Void {
        var i:Int32 = 0;
        var c:Int32 = 0;
        var m:Int32 = Std.int(Math.min(v.t, t));
        while (i < m) {
            c += a[i] - v.a[i];
            r.a[i++] = c & DM;
            c = c >> DB;
        }
        if (v.t < t) {
            c -= v.s;
            while (i < t) {
                c += a[i];
                r.a[i++] = c & DM;
                c = c >> DB;
            }
            c += s;
        }
        else {
            c += s;
            while (i < v.t) {
                c -= v.a[i];
                r.a[i++] = c & DM;
                c = c >> DB;
            }
            c -= v.s;
        }
        r.s = ((c < 0)) ? -1 : 0;
        if (c < -1) {
            r.a[i++] = DV + c;
        } else if (c > 0) {
            r.a[i++] = c;
        }
        r.t = i;
        r.clamp();
    }

    /**
     * am: Compute w_j += (x*this_i), propagates carries,
     * c is initial carry, returns final carry.
     * c < 3*dvalue, x < 2*dvalue, this_i < dvalue
     */
	
    public function am(i:Int32, x:Int32, w:BigInteger, j:Int32, c:Int32, n:Int32):Int32 {
        var DB2:Int32 = Std.int(DB / 2);
        var DB2M:Int32 = (2 << (DB2 - 1)) - 1;
		var DBM:Int32 = (2 << (DB - 1)) - 1;
        var xl:Int32 = x & DB2M;
        var xh:Int32 = x >> DB2;
        while (--n >= 0) {
            var l:Int32 = a[i] & DB2M;
            var h:Int32 = a[i++] >> DB2;
            var m:Int32 = xh * l + h * xl;
            l = xl * l + ((m & DB2M) << DB2) + w.a[j] +  (c & DBM);// (c & 0xfffffff);
            c = (l >>> DB) + (m >>> DB2) + xh * h + (c >>> DB);
            w.a[j++] = l & DBM;// B0xfffffff;
        }
        return c;
    }

    /**
     * r = this * v, r != this,a (HAC 14.12)
     * "this" should be the larger one if appropriate
     */

    public function multiplyTo(v:BigInteger, r:BigInteger):Void {
        var x:BigInteger = abs();
        var y:BigInteger = v.abs();
        var i:Int32 = x.t;
        r.t = i + y.t;
        while (--i >= 0) 
			r.a[i] = 0;
        for (i in 0...y.t) 
			r.a[i + x.t] = x.am(0, y.a[i], r, i, 0, x.t);
        r.s = 0;
        r.clamp();
        if (s != v.s) 
			ZERO.subTo(r, r);
    }

    public function square():BigInteger {
        var out = new BigInteger();
        this.squareTo(out);
        return out;
    }

    /**
     * r = this^2, r != this (HAC 14.16)
     */

    public function squareTo(r:BigInteger):Void {
        if (false) {
		    this.multiplyTo(this, r);
        } else {
            var x:BigInteger = abs();
            var i:Int32 = r.t = 2 * x.t;
            while (--i >= 0) 
				r.a[i] = 0;
            //trace(r.a);
            for (i in 0...(x.t-1)) {
                //trace(i);
                var c:Int32 = x.am(i, x.a[i], r, 2 * i, 0, 1);
                r.a[i + x.t] += x.am(i + 1, 2 * x.a[i], r, 2 * i + 1, c, x.t - i - 1);
                r.a[i + x.t] |= 0;
                if (r.a[i + x.t] >= DV) {
                    r.a[i + x.t] -= DV;
                    r.a[i + x.t] |= 0; //why is it here?
                    r.a[i + x.t + 1] = 1;
                }
            }
			i = x.t - 1; //otherwise i=-1
            if (r.t > 0) 
				r.a[r.t - 1] += x.am(i, x.a[i], r, 2 * i, 0, 1);
            r.s = 0;
            r.clamp();
        }
    }

    /**
     * divide this by m, quotient and remainder to q, r (HAC 14.20)
     * r != q, this != m. q or r may be null.
     */
    public function divRemTo(m:BigInteger, q:BigInteger = null, r:BigInteger = null, debug:Bool=false):Void {
        var pm:BigInteger = m.abs();
        if (pm.t <= 0) return;
        var pt:BigInteger = abs();
        if (pt.t < pm.t) {
            if (q != null) q.fromInt(0);
            if (r != null) copyTo(r);
            return;
        }
        if (r == null) r = nbi();
        var y:BigInteger = nbi();
        var ts:Int32 = s;
        var ms:Int32 = m.s;
        var nsh = DB - Std2.nbits(pm.a[pm.t - 1]); // normalize modulus
		if (nsh > 0) {
            pm.lShiftTo(nsh, y);
            pt.lShiftTo(nsh, r);
        } else {
            pm.copyTo(y);
            pt.copyTo(r);
        }
		if (debug){
			trace("pm= "+pm.toString(16));
			trace("pt= "+pt.toString(16));
			trace("y= "+y.toString(16));
			trace("r= "+r.toString(16));
		}
		var ys:Int = y.t;
        var y0:Int = y.a[ys - 1];
        if (y0 == 0) 
			return;
        var yt:Float = y0 * 1.0 * (1 << F1) + (((ys > 1)) ? y.a[ys - 2] >> F2 : 0);
        var d1:Float = FV / yt;
        var d2:Float = (1 << F1) / yt;
        var e:Float = 1 << F2;
        var i:Int32 = r.t;
        var j:Int32 = i - ys;
        var t:BigInteger = ((q == null)) ? nbi() : q;
        y.dlShiftTo(j, t);
        if (debug){
			trace("y0= "+y0);
			trace("ys= "+ys);
			trace("yt= "+yt);
			trace("d1= "+d1);
			trace("i= "+i);
			trace("j= "+j);
			trace("t= "+t.toString(16));
		}
		if (r.compareTo(t) >= 0) {
            r.a[r.t++] = 1;
            r.subTo(t, r);
        }
        ONE.dlShiftTo(ys, t);
        t.subTo(y, y); // "negative" y so we can replace sub with am later.
        while (y.t < ys) {
            y.a[y.t++] = 0;
            //y.(y.t++, 0);
            trace('************');
            throw new Error("Not implemented y.(y.t++, 0);");
        }
        while (--j >= 0) {
            //trace('[a] : $j');
            // Estimate quotient digit
            var qd:Int = ((r.a[--i] == y0)) ? DM : Math.floor((r.a[i]) * d1 + ((r.a[i - 1]) + e) * d2);
			if (debug)
				trace("qd= "+qd);
            if ((r.a[i] += y.am(0, qd, r, j, 0, ys)) < qd) { // Try it out
                y.dlShiftTo(j, t);
                r.subTo(t, r);
                while (r.a[i] < --qd) {
                    //trace('[b]');
                    r.subTo(t, r);
                }
            }
        }
        if (q != null) {
			r.drShiftTo(ys, q);
            if (ts != ms) ZERO.subTo(q, q);
        }
		if (debug)
			trace(r.toString(16));
        r.t = ys;
        r.clamp();
        if (nsh > 0) 
			r.rShiftTo(nsh, r);
        if (ts < 0) 
			ZERO.subTo(r, r);
    }

    /**
     * return "-1/this % 2^DB"; useful for Mont. reduction
     * justification:
     *         xy == 1 (mod n)
     *         xy =  1+km
     * 	 xy(2-xy) = (1+km)(1-km)
     * x[y(2-xy)] =  1-k^2.m^2
     * x[y(2-xy)] == 1 (mod m^2)
     * if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
     * should reduce x and y(2-xy) by m^2 at each step to keep size bounded
     * [XXX unit test the living shit out of this.]
     */
    public function invDigit():Int {
        if (t < 1) return 0;
        var x:Int32 = a[0];
        if ((x & 1) == 0) return 0;
        var y:Int32 = x & 3; // y == 1/x mod 2^2
        y = (y * (2 - (x & 0xf) * y)) & 0xf; // y == 1/x mod 2^4
        y = (y * (2 - (x & 0xff) * y)) & 0xff; // y == 1/x mod 2^8
        y = (y * (2 - (((x & 0xffff) * y) & 0xffff))) & 0xffff; // y == 1/x mod 2^16
        // last step - calculate inverse mod DV directly;
        // assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
        // XXX 48 bit ints? Whaaaa? is there an implicit float conversion in here?
        y = (y * (2 - x * y % DV)) % DV; // y == 1/x mod 2^dbits
        // we really want the negative inverse, and -DV < y < DV
        return ((y > 0)) ? DV - y : -y;
    }

    /**
     * true iff this is even
     */

    public function isEven():Bool {
        return (((t > 0)) ? (a[0] & 1) : s) == 0;
    }

    public function isOdd():Bool {
        return !isEven();
    }

    /**
     * this^e, e < 2^32, doing sqr and mul with "r" (HAC 14.79)
     */
	private static inline var XFFFFFFFF:UInt = 0xffffffff;
	 
    public function exp(e:UInt, z:IReduction):BigInteger {
        //trace('aaaaaaaaaaaaa:$e');
		//if (e > 0xffffffff) return ONE; // use cast to avoid compile time error on flash target
		if (e > XFFFFFFFF || e < 1) return ONE; // use cast to avoid compile time error on flash target
        var r = nbi();
        var r2 = nbi();
        var g = z.convert(this);
        var i:Int32 = Std2.nbits(cast e) - 1;
        //trace(i);
        g.copyTo(r);
        //g.copyTo(r2);
        //trace('result: $r');
        //trace('e: $r2');
        while (--i >= 0) {
            z.sqrTo(r, r2);
            if ((e & (1 << i)) > 0) {
                z.mulTo(r2, g, r);
            } else {
                var t = r;
                r = r2;
                r2 = t;
            }
            //trace(r);
        }
        //trace(r);
        return z.revert(r);
    }

    /*
    			if (e > 0xffffffff || e < 1) return ONE;
			var r:BigInteger = nbi();
			var r2:BigInteger = nbi();
			var g:BigInteger = z.convert(this);
			var i:int = nbits(e)-1;
			g.copyTo(r);
			while(--i>=0) {
				z.sqrTo(r, r2);
				if ((e&(1<<i))>0) {
					z.mulTo(r2,g,r);
				} else {
					var t:BigInteger = r;
					r = r2;
					r2 = t;
				}

			}
			return z.revert(r);

     */

    public function intAt(str:String, index:Int32):Int32 {
        return Std2.parseInt(str.charAt(index), 36);
    }

    private function nbi():BigInteger {
        return new BigInteger();
    }

    /**
     * return bigint initialized to value
     */

    public static function nbv(value:Int):BigInteger {
        return new BigInteger().fromInt(value);
    }

    // Functions above are sufficient for RSA encryption.
    // The stuff below is useful for decryption and key generation

    public static var lowprimes:Array<Int32> = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509];
    public static var lplim:Int = Std.int((1 << 26) / lowprimes[lowprimes.length - 1]);


    public function clone():BigInteger {
        return new BigInteger().copyFrom(this);
    }

    /**
     *
     * @return value as integer
     *
     */

    public function intValue():Int32 {
        if (s < 0) {
            if (t == 1) return a[0] - DV;
            if (t == 0) return -1;
        } else if (t == 1) {
            return a[0];
        } else if (t == 0) { // assumes 16 < DB < 32
            return 0;
        }

        return ((a[1] & ((1 << (32 - DB)) - 1)) << DB) | a[0];
    }

    /**
     * @return value as byte
     */

    public function byteValue():Int32 {
        return ((t == 0)) ? s : (a[0] << 24) >> 24;
    }

    /**
     * @return value as short (assumes DB>=16)
     */
    public function shortValue():Int32 {
        return ((t == 0)) ? s : (a[0] << 16) >> 16;
    }

    /**
     * @param r
     * @return x s.t. r^x < DV
     */

    public function chunkSize(r:Float):Int32 {
        return Math.floor(getLN2() * DB / Math.log(r));
    }

    static public function getLN2():Float {
        //return Math.LN2;
        //throw new Error('Not implemented Math.LN2');
        return 0.6931471805599453;
    }

    /**
     * @return 0 if this ==0, 1 if this >0
     */

    public function sigNum():Int32 {
        if (s < 0) return -1;
        if (t <= 0 || (t == 1 && a[0] <= 0)) return 0;
        return 1;
    }

    /**
     *
     * @param b: radix to use
     * @return a string representing the integer converted to the radix.
     *
     */

    public function toRadix(b:Int32 = 10):String {
        if (sigNum() == 0 || b < 2 || b > 32) return "0";
        var cs = chunkSize(b);
        var a = Math.pow(b, cs);
        var d = nbv(Std.int(a));
        var y = nbi();
        var z = nbi();
        var r = "";
        divRemTo(d, y, z);
        while (y.sigNum() > 0) {
            r = Std2.string(Std.int(a + z.intValue()), b).substr(1) + r;
            y.divRemTo(d, y, z);
        }
        return Std2.string(z.intValue(), b) + r;
    }

    /**
     *
     * @param s a string to convert from using radix.
     * @param b a radix
     *
     */

    public function fromRadix(s:String, b:Int = 10):BigInteger {
        fromInt(0);
        var cs:Int = chunkSize(b);
        var d:Float = Math.pow(b, cs);
        var mi:Bool = false;
        var j:Int = 0;
        var w:Int = 0;
        for (i in 0...s.length) {
            if (s.charAt(i) == "-" && sigNum() == 0) {
                mi = true;
                continue;
            }

            var x:Int = intAt(s, i);
            if (x < 0) {
                continue;
            }
            w = b * w + x;
            if (++j >= cs) {
                dMultiply(Std.int(d));
                dAddOffset(w, 0);
                j = 0;
                w = 0;
            }
        }
        if (j > 0) {
            dMultiply(Std.int(Math.pow(b, j)));
            dAddOffset(w, 0);
        }
        if (mi) BigInteger.ZERO.subTo(this, this);
        return this;
    }

    // XXX function fromNumber not written yet.

    /**
     *
     * @return a byte array.
     *
     */
    public function toByteArray():ByteArray {
        var i:Int = t;
        var r:ByteArray = new ByteArray();
        r[0] = s;
        var p:Int = DB - (i * DB) % 8;
        var d:Int;
        var k:Int = 0;
        if (i-- > 0) {
            if (p < DB && (d = a[i] >> p) != (s & DM) >> p) {
                r[k++] = d | (s << (DB - p));
            }
            while (i >= 0) {
                if (p < 8) {
                    d = (a[i] & ((1 << p) - 1)) << (8 - p);
                    d |= a[--i] >> (p += DB - 8);
                }
                else {
                    d = (a[i] >> (p -= 8)) & 0xff;
                    if (p <= 0) {
                        p += DB;
                        --i;
                    }
                }
                if ((d & 0x80) != 0) 
					d |= -256;
                if (k == 0 && (s & 0x80) != (d & 0x80)) 
					++k;
                if (k > 0 || d != s) 
					r[k++] = d;
            }
        }
        return r;
    }

    public function equals(a:BigInteger):Bool {
        return compareTo(a) == 0;
    }

    public function min(a:BigInteger):BigInteger {
        return ((compareTo(a) < 0)) ? this : a;
    }

    public function max(a:BigInteger):BigInteger {
        return ((compareTo(a) > 0)) ? this : a;
    }

    /**
     *
     * @param a	a BigInteger to perform the operation with
     * @param op a Function implementing the operation
     * @param r a BigInteger to store the result of the operation
     *
     */

    public function bitwiseTo(a:BigInteger, op:Int32 -> Int32 -> Int32, r:BigInteger):Void {
        var i:Int;
        var f:Int;
        var m:Int = Std.int(Math.min(a.t, t));
        for (i in 0...m) r.a[i] = cast op(cast this.a[i], cast a.a[i]);
        if (a.t < t) {
            f = a.s & DM;
            for (i in m...t) r.a[i] = cast op(cast this.a[i], cast f);
            r.t = t;
        }
        else {
            f = s & DM;
            for (i in m...a.t) r.a[i] = cast op(cast f, cast a.a[i]);
            r.t = a.t;
        }
        r.s = op(s, a.s);
        r.clamp();
    }

    public function and(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        bitwiseTo(a, Std2.op_and, r);
        return r;
    }

    public function or(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        bitwiseTo(a, Std2.op_or, r);
        return r;
    }

    public function xor(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        bitwiseTo(a, Std2.op_xor, r);
        return r;
    }

    public function andNot(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        bitwiseTo(a, Std2.op_andnot, r);
        return r;
    }

    public function not():BigInteger {
        var r:BigInteger = new BigInteger();
        for (i in 0...t) r.set(i, DM & ~a[i]);
        r.t = t;
        r.s = ~s;
        return r;
    }

    public function shiftLeft(n:Int32):BigInteger {
        var r = new BigInteger();
        if (n < 0) rShiftTo(-n, r); else lShiftTo(n, r);
        return r;
    }

    public function shiftRight(n:Int32):BigInteger {
        var r = new BigInteger();
        if (n < 0) lShiftTo(-n, r); else rShiftTo(n, r);
        return r;
    }

    /**
     *
     * @return index of lowest 1-bit (or -1 if none)
     *
     */

    public function getLowestSetBit():Int32 {
        for (i in 0...t) if (a[i] != 0) return i * DB + Std2.lbit(cast a[i]);
        if (s < 0) return t * DB;
        return -1;
    }

    /**
     *
     * @return number of set bits
     *
     */

    public function bitCount():Int32 {
        var r:Int = 0;
        var x:Int = s & DM;
        for (i in 0...t) r += cast Std2.cbit(cast a[i] ^ x);
        return r;
    }

    /**
     *
     * @param n
     * @return true iff nth bit is set
     *
     */
    public function testBit(n:Int32):Bool {
        var j = Math.floor(n / DB);
        if (j >= t) return s != 0;
        return ((a[j] & (1 << (n % DB))) != 0);
    }

    /**
     *
     * @param n
     * @param op
     * @return this op (1<<n)
     *
     */
    public function changeBit(n:Int32, op:Int32 -> Int32 -> Int32):BigInteger {
        var r:BigInteger = BigInteger.ONE.shiftLeft(n);
        bitwiseTo(r, op, r);
        return r;
    }

    /**
     *
     * @param n
     * @return this | (1<<n)
     *
     */

    public function setBit(n:Int32):BigInteger {
        return changeBit(n, Std2.op_or);
    }

    /**
     *
     * @param n
     * @return this & ~(1<<n)
     *
     */

    public function clearBit(n:Int32):BigInteger {
        return changeBit(n, Std2.op_andnot);
    }

    /**
     *
     * @param n
     * @return this ^ (1<<n)
     *
     */

    public function flipBit(n:Int32):BigInteger {
        return changeBit(n, Std2.op_xor);
    }

    /**
     *
     * @param a
     * @param r = this + a
     *
     */

    private function addTo(a:BigInteger, r:BigInteger):Void {
        var i:Int = 0;
        var c:Int = 0;
        var m:Int = Std.int(Math.min(a.t, t));
        while (i < m) {
            c += this.a[i] + a.a[i];
            r.a[i++] = c & DM;
            c = c >> DB;
        }
        if (a.t < t) {
            c += a.s;
            while (i < t) {
                c += this.a[i];
                r.a[i++] = c & DM;
                c = c >> DB;
            }
            c += s;
        }
        else {
            c += s;
            while (i < a.t) {
                c += a.a[i];
                r.a[i++] = c & DM;
                c = c >> DB;
            }
            c += a.s;
        }
        r.s = ((c < 0)) ? -1 : 0;
        if (c > 0) {
            r.a[i++] = c;
        }
        else if (c < -1) {
            r.a[i++] = DV + c;
        }
        r.t = i;
        r.clamp();
    }

    /**
     *
     * @param a
     * @return this + a
     *
     */

    public function add(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        addTo(a, r);
        return r;
    }

    /**
     *
     * @param a
     * @return this - a
     *
     */

    public function subtract(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        subTo(a, r);
        return r;
    }

    /**
     *
     * @param a
     * @return this * a
     *
     */

    public function multiply(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        multiplyTo(a, r);
        return r;
    }

    /**
     *
     * @param a
     * @return this / a
     *
     */

    public function divide(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        divRemTo(a, r, null);
        return r;
    }

    public function remainder(a:BigInteger):BigInteger {
        var r:BigInteger = new BigInteger();
        divRemTo(a, null, r);
        return r;
    }

    /**
     *
     * @param a
     * @return [this/a, this%a]
     *
     */

    public function divideAndRemainder(a:BigInteger):Array<BigInteger> {
        var q = new BigInteger();
        var r = new BigInteger();
        divRemTo(a, q, r);
        return [q, r];
    }

    /**
     *
     * this *= n, this >=0, 1 < n < DV
     *
     * @param n
     *
     */

    public function dMultiply(n:Int32):Void {
        a[t] = am(0, n - 1, this, 0, 0, t);
        ++t;
        clamp();
    }

    /**
     *
     * this += n << w words, this >= 0
     *
     * @param n
     * @param w
     *
     */

    public function dAddOffset(n:Int32, w:Int32):Void {
        while (t <= w) a[t++] = 0;
        a[w] += n;
        while (a[w] >= DV) {
            a[w] -= DV;
            if (++w >= t) a[t++] = 0;
            ++a[w];
        }
    }

    /**
     *
     * @param e
     * @return this^e
     *
     */

    public function pow(e:Int32):BigInteger {
        //var out = new BigInteger().copyFrom(this);
        //var temp = new BigInteger().copyFrom(this);
        //var one = new BigInteger().copyFrom(this);
        //trace(':::::::: $out');
        //trace(':::::::: $one');
        //for (n in 0 ... e) {
        //    new BigInteger().copyFrom(out).multiplyTo(one, out);
        //    trace(':::::::: $out');
        //}
        //return out;
        return exp(cast e, new NullReduction());
        //return exp(cast e, new ClassicReduction(this));
    }

    /**
     *
     * @param a
     * @param n
     * @param r = lower n words of "this * a", a.t <= n
     *
     */

    public function multiplyLowerTo(a:BigInteger, n:Int32, r:BigInteger):Void {
        var i:Int = Std.int(Math.min(t + a.t, n));
        r.s = 0; // assumes a, this >= 0
        r.t = i;
        while (i > 0) r.a[--i] = 0;
        var j = r.t - t;
        while (i < j) {
            r.a[i + t] = am(0, a.a[i], r, i, 0, t);
            i++;
        }
        j = Std.int(Math.min(a.t, n));
        while (i < j) {
            am(0, a.a[i], r, i, 0, n - i);
            i++;
        }
        r.clamp();
    }

    /**
     *
     * @param a
     * @param n
     * @param r = "this * a" without lower n words, n > 0
     *
     */
    public function multiplyUpperTo(a:BigInteger, n:Int32, r:BigInteger):Void {
        n--;
        var i:Int = r.t = t + a.t - n;
        r.s = 0; // assumes a,this >= 0
        while (--i >= 0) r.a[i] = 0;
        for (i in Std.int(Math.max(n - t, 0))...a.t) r.a[t + i - n] = am(n - i, a.a[i], r, 0, 0, t + i - n);
        r.clamp();
        r.drShiftTo(1, r);
    }

    /**
     *
     * @param e
     * @param m
     * @return this^e % m (HAC 14.85)
     *
     */
    public function modPow(e:BigInteger, m:BigInteger):BigInteger {
        var i:Int = e.bitLength();
        var r:BigInteger = nbv(1);
        var z:IReduction;

        if (i <= 0) return r;

        var k:Int = (
            if (i < 18) 1;
            else if (i < 48) 3;
            else if (i < 144) 4;
            else if (i < 768) 5;
            else 6
        );

        var z = (
            if (i < 8) new ClassicReduction(m);
            else if (m.isEven()) new BarrettReduction(m); // precomputation
            else new MontgomeryReduction(m)
        );

        var g:Array<BigInteger> = [];
        var n:Int = 3;
        var k1:Int = k - 1;
        var km:Int = (1 << k) - 1;
        g[1] = z.convert(this);
        if (k > 1) {
            var g2 = new BigInteger();
            z.sqrTo(g[1], g2);
            while (n <= km) {
                g[n] = new BigInteger();
                z.mulTo(g2, g[n - 2], g[n]);
                n += 2;
            }
        }

        var j:Int32 = e.t - 1;
        var w:Int;
        var is1 = true;
        var r2 = new BigInteger();
        i = Std2.nbits(cast e.a[j]) - 1;
        while (j >= 0) {
            if (i >= k1) {
                w = (e.a[j] >> (i - k1)) & km;
            }
            else {
                w = (e.a[j] & ((1 << (i + 1)) - 1)) << (k1 - i);
                if (j > 0) {
                    w |= e.a[j - 1] >> (DB + i - k1);
                }
            }
            n = k;
            while ((w & 1) == 0) { w = w >> 1; --n; }
            if ((i -= n) < 0) { i += DB; --j; }

            if (is1) { // ret == 1, don't bother squaring or multiplying it
                g[w].copyTo(r);
                is1 = false;
            } else {
                while (n > 1) {
                    z.sqrTo(r, r2);
                    z.sqrTo(r2, r);
                    n -= 2;
                }
                if (n > 0) {
                    z.sqrTo(r, r2);
                } else {
                    var t = r;
                    r = r2;
                    r2 = t;
                }
                z.mulTo(r2, g[w], r);
            }

            while (j >= 0 && (e.a[j] & (1 << i)) == 0) {
                z.sqrTo(r, r2);
                var t = r;
                r = r2;
                r2 = t;
                if (--i < 0) {
                    i = DB - 1;
                    --j;
                }
            }
        }
        return z.revert(r);
    }

    /**
     *
     * @param a
     * @return gcd(this, a) (HAC 14.54)
     *
     */

    public function gcd(a:BigInteger):BigInteger {
        var x:BigInteger = ((s < 0)) ? negate() : clone();
        var y:BigInteger = ((a.s < 0)) ? a.negate() : a.clone();
        if (x.compareTo(y) < 0) {
            var t = x;
            x = y;
            y = t;
        }
        var i:Int = x.getLowestSetBit();
        var g:Int = y.getLowestSetBit();
        if (g < 0) return x;
        if (i < g) g = i;
        if (g > 0) {
            x.rShiftTo(g, x);
            y.rShiftTo(g, y);
        }
        while (x.sigNum() > 0) {
            if ((i = x.getLowestSetBit()) > 0) x.rShiftTo(i, x);
            if ((i = y.getLowestSetBit()) > 0) y.rShiftTo(i, y);

            if (x.compareTo(y) >= 0) {
                x.subTo(y, x);
                x.rShiftTo(1, x);
            } else {
                y.subTo(x, y);
                y.rShiftTo(1, y);
            }
        }
        if (g > 0) y.lShiftTo(g, y);
        return y;
    }

    /**
     *
     * @param n
     * @return this % n, n < 2^DB
     *
     */
    public function modInt(n:Int32):Int32 {
        if (n <= 0) return 0;
        var d = DV % n;
        var r = ((s < 0)) ? n - 1 : 0;
        if (t > 0) {
            if (d == 0) {
                r = a[0] % n;
            } else {
                var i:Int = t - 1;
                while (i >= 0) {
                    r = (d * r + a[i]) % n;
                    --i;
                }
            }
        }
        return r;
    }

    /**
     *
     * @param m
     * @return 1/this %m (HAC 14.61)
     *
     */

    public function modInverse(m:BigInteger):BigInteger {
        var ac:Bool = m.isEven();
        if ((isEven() && ac) || m.sigNum() == 0) return BigInteger.ZERO;
        var u = m.clone();
        var v = clone();
        var a = nbv(1);
        var b = nbv(0);
        var c = nbv(0);
        var d = nbv(1);
        while (u.sigNum() != 0) {
            while (u.isEven()) {
                u.rShiftTo(1, u);
                if (ac) {
                    if (!a.isEven() || !b.isEven()) {
                        a.addTo(this, a);
                        b.subTo(m, b);
                    }
                    a.rShiftTo(1, a);
                } else if (!b.isEven()) {
                    b.subTo(m, b);
                }
                b.rShiftTo(1, b);
            }
            while (v.isEven()) {
                v.rShiftTo(1, v);
                if (ac) {
                    if (!c.isEven() || !d.isEven()) {
                        c.addTo(this, c);
                        d.subTo(m, d);
                    }
                    c.rShiftTo(1, c);
                } else if (!d.isEven()) {
                    d.subTo(m, d);
                }
                d.rShiftTo(1, d);
            }
            if (u.compareTo(v) >= 0) {
                u.subTo(v, u);
                if (ac) a.subTo(c, a);
                b.subTo(d, b);
            } else {
                v.subTo(u, v);
                if (ac) c.subTo(a, c);
                d.subTo(b, d);
            }
        }
        if (v.compareTo(BigInteger.ONE) != 0) return BigInteger.ZERO;
        if (d.compareTo(m) >= 0) return d.subtract(m);

        if (d.sigNum() < 0) {
            d.addTo(m, d);
        } else {
            return d;
        }

        return (d.sigNum() < 0) ? d.add(m) : d;
    }

    /**
     *
     * @param t
     * @return primality with certainty >= 1-.5^t
     *
     */

    public function isProbablePrime(t:Int32):Bool {
        var i:Int32;
        var x:BigInteger = abs();
        if (x.t == 1 && x.a[0] <= lowprimes[lowprimes.length - 1]) {
            for (i in 0...lowprimes.length) {
                if (x.get(0) == lowprimes[i]) return true;
                //throw new Error('bug? BigInteger[0]?');
            }
            return false;
        }
        if (x.isEven()) return false;
        i = 1;
        while (i < lowprimes.length) {
            var m:Int = lowprimes[i];
            var j:Int = i + 1;
            while (j < lowprimes.length && m < lplim) {
                m *= lowprimes[j++];
            }
            m = x.modInt(m);
            while (i < j) {
                if (m % lowprimes[i++] == 0) {
                    return false;
                }
            }
        }
        return x.millerRabin(t);
    }

    /**
     *
     * @param t
     * @return true if probably prime (HAC 4.24, Miller-Rabin)
     *
     */

    public function millerRabin(t:Int32):Bool {
        var n1:BigInteger = subtract(BigInteger.ONE);
        var k:Int32 = n1.getLowestSetBit();
        if (k <= 0) {
            return false;
        }
        var r = n1.shiftRight(k);
        t = (t + 1) >> 1;
        if (t > lowprimes.length) {
            t = lowprimes.length;
        }
        var a = new BigInteger();
        for (i in 0...t) {
            a.fromInt(lowprimes[i]);
            var y = a.modPow(r, this);
            if (y.compareTo(BigInteger.ONE) != 0 && y.compareTo(n1) != 0) {
                var j:Int = 1;
                while (j++ < k && y.compareTo(n1) != 0) {
                    y = y.modPowInt(2, this);
                    if (y.compareTo(BigInteger.ONE) == 0) return false;
                }
                if (y.compareTo(n1) != 0) return false;
            }
        }
        return true;
    }

    /**
     * Tweak our BigInteger until it looks prime enough
     *
     * @param bits
     * @param t
     *
     */

    public function primify(bits:Int32, t:Int32):Void {
        if (!testBit(bits - 1)) bitwiseTo(BigInteger.ONE.shiftLeft(bits - 1), Std2.op_or, this); // force MSB set
        if (isEven()) dAddOffset(1, 0);
        while (!isProbablePrime(t)) {
            dAddOffset(2, 0);
            while (bitLength() > bits)subTo(BigInteger.ONE.shiftLeft(bits - 1), this);
        }
    }
}

