package com.hurlant.math;


/**
 * A "null" reducer
 */
class NullReduction implements IReduction {
    public function new() {
    }

    public function revert(x:BigInteger):BigInteger {
        return x.clone();
    }

    public function mulTo(x:BigInteger, y:BigInteger, r:BigInteger):Void {
        x.multiplyTo(y, r);
    }

    public function sqrTo(x:BigInteger, r:BigInteger):Void {
        x.squareTo(r);
    }

    public function convert(x:BigInteger):BigInteger {
        return x.clone();
    }

    public function reduce(x:BigInteger):Void {
    }
}
