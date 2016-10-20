#ifndef CLASTERED_SERVER_SLAVE_NPC_HEADER
#define CLASTERED_SERVER_SLAVE_NPC_HEADER

#include <map>
#include <vector>
#include "../share/system/time.h"
#include "../share/system/mutex.h"
#include "../share/network/packet.h"
#include "point.h"
#include "attrs_map.h"

extern "C"{
#include <time.h>
}


namespace clasteredServerSlave {
	class npc;
	class npc_moves;
	class npc_shoots;
	
	typedef void (npc:: *shoot_func)(typeof(point::x) x, typeof(point::y) y);
	typedef void (npc:: *move_func)(typeof(point::x) x, typeof(point::y) y);
	
	struct bot {
		bool used;
		point goal;
		int dist; //moved distance
		npc* target;
	};
	
	class npc {
		public:
			int id;
			//action attributes
			char state; //TODO: use it
			point position;
			pointf direction;
			short health;
			short type;
			int owner_id;
			char keys[4]; //x,y(l- r+ t- b+), angle	
			clasteredServerSlave::bot bot;
		
			//common attributes
			share::packet p;
			share::mutex m;
			int slave_id;
			int cell_id;
			int r; //radius of collision
			std::vector<int> cells;
			struct{
				struct{
					bool done;
					bool all; //static parameters
					bool server;
				} pack;
			} _updated;
			attrs_map attr;
			std::vector<bool> attrs; //attributes updated flags
			move_func movef;
			shoot_func shootf;

			npc(){};
			npc(int id, int slave=0, short type=0);
			~npc();
			bool clear();
			void attack();
			void move();
			void shoot();
			void set_dir();
			void set_dir(float x, float y);
			bool hurt(short d);
			void update(share::packet * p);
			bool updated(); 			
			void pack(bool all=0, bool server=0); //pack action attributes, do not pack special atributes
			int gridOwner();
			std::vector<int>& gridShares();

			static std::map<short, move_func> moves;
			static std::map<short, shoot_func> shoots;
			
			static npc* addBot(float x, float y, short type=0);
			
			friend std::ostream& operator<<(std::ostream &stream, const npc &n);
		protected:
			float vel;
			timestamp_t timestamp;
			
			bool check_point(typeof(point::x) x, typeof(point::y) y);
			bool update_cells();
		
			static npc_moves _moves;
			static npc_shoots _shoots;
	};
	
}



#endif
