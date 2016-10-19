#ifndef CLASTERED_SERVER_SLAVE_PLAYER_HEADER
#define CLASTERED_SERVER_SLAVE_PLAYER_HEADER

#include <map>
#include <string>

#include "../share/system/mutex.h"
#include "../share/network/packet.h"
#include "npc.h"


extern "C"{

}

namespace clasteredServerSlave {

	class player {
		public:
			int id;
			bool connected;
			std::string login;
			std::string pass;
			std::string name;
			share::mutex m;
			clasteredServerSlave::npc* npc;
			
			player(int id);
			~player();
			void sendUpdates();
			void move();
			void update(share::packet *p);
	};
}



#endif
