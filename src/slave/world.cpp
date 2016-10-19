
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

using namespace share;

namespace clasteredServerSlave {
	
	int world::id=0;
	float world::map_size[2]={320, 320};
	float world::map_offset=32;
	bool world::main_loop=0;
	share::mutex world::m;
	share::mutex world::new_npcs_m;
	share::grid* world::grid=0;
	share::socket* world::sock=0;
	clasteredServerSlave::map world::map(10,10);
	std::queue<int> world::ids;
	std::list<npc*>world:: new_npcs;
	std::map<int, npc*>world:: npcs;
	std::map<int, player*> world::players;

	void world::init(){
		//read data from disk and init
		grid=new share::grid(map_size, map_offset);
	}

	int world::getId(){
		packet p;
		int o=ids.front();
		if (ids.size()-1<10){
			p.setType(6);
			world::sock->send(&p);
		}
		ids.pop();
		return o;
	}
	
	void world::clear(){
		if (sock)
			delete sock;
		if (grid)
			delete grid;
	}
	
}
