#include <string.h>

#include "../share/network/listener.h"
#include "../share/system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	listeners container 				                       ║
║ created by Dennis Yarikov						                       ║
║ jul 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace master{
	
	std::vector<listener*> listeners::all;

	listener* listeners::add(listener* l){
		if (l)
			all[l->id]=l;
		return l;
	}
	
	void listeners::clear(){
		for (auto l:all){
			delete l.second;
		}
	}
}