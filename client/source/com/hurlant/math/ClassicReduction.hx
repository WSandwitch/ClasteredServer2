package com.hurlant.math;

import com.hurlant.math.IReduction;


/**
 * Modular reduction using "classic" algorithm
 */
class ClassicReduction implements IReduction {
    private var m:BigInteger;

    public function new(m:BigInteger) {
        this.m = m;
    }

    public function convert(x:BigInteger):BigInteger {
        return (x.s < 0 || x.compareTo(m) >= 0) ? x.mod(m) : x;
    }

    public function revert(x:BigInteger):BigInteger {
        return x;
    }

    public function reduce(x:BigInteger):Void {
        x.divRemTo(m, null, x);
    }

    public function mulTo(x:BigInteger, y:BigInteger, r:BigInteger):Void {
        x.multiplyTo(y, r);
        reduce(r);
    }

    public function sqrTo(x:BigInteger, r:BigInteger):Void {
        x.squareTo(r);
        reduce(r);
    }
}
