#include <queue>

#include "../share/network/packet.h"
#include "../share/system/folder.h"
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
	static mutex m_id;
	static int last=1;
	static std::queue<int> reuse;
	
	int world::getId(){
		int i;
		if (reuse.size()>0){
			m_id.lock();
				i=reuse.front();
				reuse.pop();
			m_id.unlock();
		}else{
			i=withLock(m_id, last++);
		}
		return i;
	}
	
	void world::putId(int i){
		m_id.lock();
			reuse.push(i);
		m_id.unlock();
	}
	
	world::world():
		id(0),
		map_offset(32),
		main_loop(0),
		sock(0)
	{	
//		folder::forEachFile((char*)"../maps/*.tmx", [&maps](char *s){ maps[map::getId(s)]=new map(s); });
	}
	
	world::~world(){
		if (sock)
			delete sock;
	}
	
}
