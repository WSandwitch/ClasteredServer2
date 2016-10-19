
#include "messageprocessor.h"
#include "client.h"
#include "../share/containers/bintree.h"
#include "../share/system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║  			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/



static bintree clients={0},servers={0};


void* messageprocessorClient(int key){
	return bintreeGet(&clients, key);
}

void* messageprocessorServer(int key){
	return bintreeGet(&servers, key);
}

bintree_key messageprocessorClientAdd(bintree_key key, void* f){
	return bintreeAdd(&clients, key, f);
}

bintree_key messageprocessorServerAdd(bintree_key key, void* f){
	return bintreeAdd(&servers, key, f);
}

void messageprocessorClear(){
	bintreeErase(&clients, 0);
	bintreeErase(&servers, 0);
}
