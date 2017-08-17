master [![Build Status](https://travis-ci.org/AliEn707/ClasteredServer2.svg?branch=master)](https://travis-ci.org/AliEn707/ClasteredServer2)

new_core [![Build Status](https://travis-ci.org/AliEn707/ClasteredServer2.svg?branch=new_core)](https://travis-ci.org/AliEn707/ClasteredServer2)

ClasteredServer2 is updated version of ClasteredServer, that was stopped.

## Summary

Multiplayer client server game application. Server is written on C++, client on Haxe (using HaxeFlixel lib).

## build and test

### server

only on linux

you have to have gcc g++ openssl and some other libs installed (list will be updated)

run 'make' in root dir, you can run 'make OPTIMISATION=1' if you have slow pc:-) 

### client

you have to install haxe with libs 
* flixel
* polygonal-ds 
* yaml 

and setup lime

for build and run, run 'lime test $platform'

client can be built for
* windows
* neko
* linux
* android
* flash

and may be

* mac
* ios



## running

you need to open 2 terminal windows for server (only on Linix)

build server

run './master' at first window

run './slave' at second window

after that run client


