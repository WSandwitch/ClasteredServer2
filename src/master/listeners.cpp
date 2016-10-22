#include <string.h>

#include "listeners.h"
#include "../share/system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	listeners container 				                       ║
║ created by Dennis Yarikov						                       ║
║ jul 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/
using namespace share;

namespace master{
	
	std::vector<listener*> listeners::all;

	listener* listeners::add(listener* l){
		if (l)
			all.push_back(l);
		return l;
	}
	
	void listeners::clear(){
		for (auto l:all){
			delete l;
		}
	}
}