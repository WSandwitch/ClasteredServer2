package com.hurlant.math;

interface IReduction {
    function convert(x:BigInteger):BigInteger;
    function revert(x:BigInteger):BigInteger;
    function reduce(x:BigInteger):Void;
    function mulTo(x:BigInteger, y:BigInteger, r:BigInteger):Void;
    function sqrTo(x:BigInteger, r:BigInteger):Void;
}
