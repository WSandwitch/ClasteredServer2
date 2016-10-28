
#include "../share/network/packet.h"
#include "world.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ functions for work with sockets 			                       ║
║ created by Dennis Yarikov						                       ║
║ aug 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace std{
	ostream& operator<<(ostream &stream, const vector<int> &v) {
		cout << "[";
		for(int i=0, end=v.size();i<end;i++){
			cout << v[i];
			if (i<end-1)
				cout << ", ";
		}
		cout << "]";
		return stream;
	}
}


namespace share {
/*	
	int world::id=0;
	float world::map_size[2]={320, 320};
	float world::map_offset=32;
	bool world::main_loop=0;
	share::mutex world::m;
	share::mutex world::new_npcs_m;
	share::socket* world::sock=0;
	clasteredServerSlave::map world::map(10,10);
	std::queue<int> world::ids;
	std::list<npc*> world::new_npcs;
	std::unordered_map<int, npc*> world::npcs;
	std::map<int, player*> world::players;
*/	
	int world::getId(){
		static int id=1;
		return id++;
	}
	
	world::world():
		id(0),
		map_size({320, 320}),
		map_offset(32),
		main_loop(0),
		sock(0)
	{	}
	
	world::~world(){
		if (sock)
			delete sock;
	}
	
}
