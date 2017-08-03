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

#define NPC_FULL_TEMP 30000
#define STATE_IDLE 0
#define STATE_WARMUP 1
#define STATE_ATTACK 2
#define STATE_SHOOT 3
#define STATE_COOLDOWN 4

extern "C"{
#include <time.h>
}


namespace share {
	class npc;
	class npc_moves;
	class npc_shoots;
	class world;
	
	typedef bool (npc:: *set_attr_func)(void*, void*);
	typedef void (npc:: *shoot_func)(typeof(point::x) x, typeof(point::y) y);
	typedef void (npc:: *move_func)(typeof(point::x) x, typeof(point::y) y);
	
//	#define attr3b_key(b1, b2, b3) ((b1?1:0)|(b2?2:0)|(b3?4:0))
#define attr3b_key(b1, b2, b3) ((b1)|(b2<<1)|(b3<<2))
	
	template<class T>
		struct map3b{
			std::unordered_map<char, T> p;//TODO:maybe short?
			
			map3b(){};
			map3b(map3b& a){};//can't be copyed
			T& operator()(bool b1=0, bool b2=0, bool b3=0){
				return p[attr3b_key(b1,b2,b3)];
			};
			void clear(){p.clear();};
			typeof(p.begin()) begin(){return p.begin();};
			typeof(p.end()) end(){return p.end();};
			typeof(p.size()) size(){return p.size();};
		};
	
	struct pack_p{
		bool done;
		mutex m;
	};
		
	class npc {
		public:
			int id;
			char state; //attack state
			point position;
			pointf direction;
			short health; //curent health
			short _health; //max health
			int type; //base id
			short move_id;
			short shoot_id; 
			int weapon_id; //object_id
			int owner_id; //id of player
			char angle; //angle of view in pdegrees
			share::world *world;
			share::mutex m;
			struct{
				char used;
				point goal;
				int dist; //moved distance
				npc* target;
				int owner_id;//owner for bullet 
			} bot;
			struct{
				short temp; 
				short next_shot; //tiks
				
				char attackable; //can be attacked
				short damage; //calculated damage
				
				short ang_diap;//pdegree
				short ang_shift;//pdegree
				short attacks;
				int dist;
				
				short warmup; //NPC_FULL_TEMP/world->tps/n -> n seconds to max
				short cooldown; //set
				short latency; //tiks
			} weapon;
				
			map3b<share::packet> packs;
			map3b<std::vector<char>> pack_attrs;
			int slave_id;
			int cell_id;
			int r; //radius of collision
			std::list<int> cells;
			std::set<int> slaves;
			attrs_map attr;
			std::unordered_map<char, bool> attrs; //attributes updated flags
			int spawn_wait;
				
			char attackable;
			std::unordered_map<int, int> damagers; 
			
			npc(){};
			npc(share::world *w, int id, short type=0);
			void remove();
//			void operator delete(void *n);
			npc* clone();
			bool clear();
			void init_attrs();
			void init_position();
			void recalculate_type();
			void attack();
			void attack(bool s);
			void move();
			void shoot();
			void set_dir();
			void set_dir(float x, float y, bool to_1=1);
			float vel_angle(float max);
			bool hurt(short d);
			void hurt(npc* n);
			void make_shot(char angle);
			bool suicide(); 			
			void update(share::packet * p);
			bool updated(); 
			share::packet* pack(bool server=0, bool all=0, bool to_slave=0); //threadsafe over packet
			bool update_cells();//threadsafe
			
			template<class T>
				bool set_attr(void*, void*);//set attr on addr by type
			bool set_attr(short type, void *where, void *what);//set attr on addr by type
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
			static set_attr_func set_attr_funcs[6];
			
			static npc* addBot(share::world *world, int id, float x, float y, short type=0);
			
			friend std::ostream& operator<<(std::ostream &stream, const npc &n);
		protected:
			float vel;
			timestamp_t timestamp;
			map3b<pack_p> _packs;
			
			bool check_point(typeof(point::x) x, typeof(point::y) y);
		
			static npc_moves _moves;
			static npc_shoots _shoots;
		
	};
	
}



#endif
