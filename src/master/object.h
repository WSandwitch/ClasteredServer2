#ifndef CLASTERED_SERVER_SLAVE_OBJECT_HEADER
#define CLASTERED_SERVER_SLAVE_OBJECT_HEADER

#include <vector>
#include <string>
#include <unordered_map>

#include "../share/npc.h"

#define OBJECT_BASE 1
#define OBJECT_WEAPON 2

namespace master{

	struct object_initializer;
	
	struct object{
		int id;
		short kind;
		short type;
		int cost;
		std::vector<std::vector<int>> deps;  //object dependencies
		struct {
			int dist;
			short ang_diap; //degrees
			short ang_shift; //degrees
			short attacks; //

			float warmup; //sec
			float cooldown; //sec
			float latency; //sec
			
			short shoot_id;
			short move_id; //of shot
			char attackable; //of shot
		} weapon;
		struct {
			short health; //basic health max, of health addition
		} base; //commen for base, addition for speciales
		///----------
		object();
		void init_attrs();
		template<class T>
			T& attr_on(int a){return *((T*)((char*)this+a));}
		void apply_to(share::npc *n);
			
		static std::unordered_map<int, std::string> attr_map;
		static std::unordered_map<int, int> attr_type;
		static object_initializer initializer;
		static std::unordered_map<int, object*> all;
	};
	
	struct object_initializer : object {
		object_initializer();
		~object_initializer();
	};

};

#endif