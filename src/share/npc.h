#ifndef CLASTERED_SERVER_SLAVE_NPC_HEADER
#define CLASTERED_SERVER_SLAVE_NPC_HEADER

#include <map>
#include <unordered_map>
#include <set>
#include <list>
#include <vector>
#include "../share/system/time.h"
#include "../share/system/mutex.h"
#include "../share/network/packet.h"
#include "math/point.h"
#include "attrs_map.h"

#define NPC_FULL_TEMP 10000
#define STATE_IDLE 0
#define STATE_WARMUP 1
#define STATE_ATTACK 2
#define STATE_COOLDOWN 3

extern "C"{
#include <time.h>
}


namespace share {
	class npc;
	class npc_moves;
	class npc_shoots;
	class world;
	
	typedef void (npc:: *shoot_func)(typeof(point::x) x, typeof(point::y) y);
	typedef void (npc:: *move_func)(typeof(point::x) x, typeof(point::y) y);
	
	template<class T>
		struct multi_map{
			std::unordered_map<int, T> p;
			T* operator()(bool b1=0, bool b2=0, bool b3=0){
				return &p[b1?1:0+b2?10:0+b3?100:0];
			}
		};
	
	struct bot {
		char used;
		point goal;
		int dist; //moved distance
		npc* target;
	};
	
	class npc {
		public:
			int id;
			char state; //attack state
			point position;
			pointf direction;
			short health; //curent health
			short damage; //calculated damage
			short type; //
			short move_id;
			short shoot_id; 
			short weapon_id; 
			int owner_id; //id of player
			char angle; //angle of view
//			char keys[4]; //x,y(l- r+ t- b+), angle	
			share::bot bot;
			share::world *world;
			struct{
				short temp;
				short next_shot;
			} weapon;
				
			share::packet p;
			share::mutex m;
			int slave_id;
			int cell_id;
			int r; //radius of collision
			std::list<int> cells;
			std::set<int> slaves;
			struct{
				struct{
					bool done;
					bool all; //static parameters
					bool server;
					bool to_slave;
				} pack;
			} _updated;
			attrs_map attr;
			std::unordered_map<char, bool> attrs; //attributes updated flags
			
			npc(){};
			npc(share::world *w, int id, int slave=0, short type=0);
			~npc();
			bool clear();
			void attack();
			void move();
			void shoot();
			void set_dir();
			void set_dir(float x, float y);
			bool hurt(short d);
			void hurt(npc* n);
			void update(share::packet * p);
			bool updated(); 			
			void pack(bool server=0, bool all=0, bool to_slave=0); //pack action attributes, do not pack special atributes
			bool update_cells();//return 1 if updated
			
			template<class T1, class T2>
			T1 set_attr(T1 &a, T2 v){
				T1 $=a;
				a=v;
				attrs[attr(&a)]=1;
				return $;
			};
//			std::vector<int>& gridShares();

			static std::unordered_map<short, move_func> moves;
			static std::unordered_map<short, shoot_func> shoots;
			
			static npc* addBot(share::world *world, int id, float x, float y, short type=0);
			
			friend std::ostream& operator<<(std::ostream &stream, const npc &n);
		protected:
			float vel;
			timestamp_t timestamp;
			
			bool check_point(typeof(point::x) x, typeof(point::y) y);
		
			static npc_moves _moves;
			static npc_shoots _shoots;
	};
	
}



#endif
