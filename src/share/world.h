#ifndef CLASTERED_SERVER_SLAVE_WORLD_HEADER
#define CLASTERED_SERVER_SLAVE_WORLD_HEADER

#include <map>
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

#define MASTER_MESSAGE 0
#define CLIENT_MESSAGE 1
#define SERVER_MESSAGE 2

#define MSG_MASTER_MOVE_CLIENT 4 //{cl_id,sv_id}

#define MSG_CLIENT_NPC_UPDATE 40
#define MSG_CLIENT_UPDATE 41
#define MSG_CLIENT_PLAYER_INFO 42

#define MSG_SERVER_NPC_INFO 40 
#define MSG_SERVER_NPC_UPDATE 41 
#define MSG_SERVER_PLAYER_INFO 42

namespace std{
	ostream& operator<<(ostream &stream, const vector<int> &v);
}

namespace share {

	struct world {
		int id;
		float map_size[2];
		float map_offset;
		bool main_loop;
		share::mutex m;
		share::mutex new_npcs_m;
		share::socket* sock;
		share::map map;
		std::queue<int> ids;
		std::list<npc*> new_npcs;
		std::unordered_map<int, npc*> npcs;
		
		world();
		~world();
	};
}



#endif
