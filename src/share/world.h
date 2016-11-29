#ifndef CLASTERED_SERVER_SLAVE_WORLD_HEADER
#define CLASTERED_SERVER_SLAVE_WORLD_HEADER

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
		float map_size[2];
		float map_offset;
		bool main_loop;
		short tps;
		share::mutex m;
		share::mutex npcs_m;
		share::socket* sock;
		share::map map;
		std::queue<int> ids;
		std::list<npc*> new_npcs;
		std::unordered_set<int> old_npcs;
		std::unordered_map<int, npc*> npcs;
		
		world();
		~world();
		
		static int getId();
	};
}



#endif
