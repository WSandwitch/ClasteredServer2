
#include <map>

#include "messageprocessor.h"
#include "client.h"
#include "../share/system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║  			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/



static std::map<int, void*> clients,servers;


void* messageprocessorClient(int key){
	return clients[key];
}

void* messageprocessorServer(int key){
	return servers[key];
}

bintree_key messageprocessorClientAdd(int key, void* f){
	return clients[key]=(void*)f;
}

bintree_key messageprocessorServerAdd(int key, void* f){
	return servers[key]=(void*)f);
}

