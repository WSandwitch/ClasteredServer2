#pragma once

#include <map>
#include <unordered_set>
#include <unordered_map>
#include <list>
#include <queue>
#include <vector>
#include <iostream>

#include "npc.h"
#include "map.h"
#include "../share/network/socket.h"
#include "../share/system/mutex.h"

extern "C"{
	struct char2{
		char x,y;
	};
}


namespace std{
	ostream& operator<<(ostream &stream, const vector<int> &v);
}

namespace share {

	struct world {
		int id;
		float map_offset;
		bool main_loop;
		bool pause;
		short tps;
		share::mutex m;
		share::mutex npcs_m;
		share::socket* sock;
//		share::map* map;
		std::unordered_map<int, share::map*> maps; 
		std::list<npc*> new_npcs;
		std::unordered_set<int> old_npcs;
		std::unordered_map<int, npc*> npcs;
		
		world();
		~world();
		
		static int getId();
		static void putId(int id);
	};
	
	
	//TODO: move out of here
	template<class T>
		int npc::do_on_map(T f){
			try{
				return f(world->maps.at(map_id));
			}catch(...){
				printf("npc %d has unknown map\n", id);
				set_attr(map_id, 0); //set default map, it must be exists
			}
			return 0;
		}
}
