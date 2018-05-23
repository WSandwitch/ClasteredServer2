#ifndef CLASTERED_SERVER_SLAVE_OBJECT_HEADER
#define CLASTERED_SERVER_SLAVE_OBJECT_HEADER

#include <vector>
#include <string>
#include <unordered_map>

#include "math/point.h"

#define OBJECT_BASE 1
#define OBJECT_WEAPON 2
#define OBJECT_BULLET 3

//TODO: move to master
namespace share{
	struct object_initializer;
	
	struct OMODATTR{
		enum OBJECT_MOD_ATTR:int{
			HEALTH=1, //_health
			DAMAGE=2, //weapon.damage
			DIST=3, //weapon.dist
			R=4, //r
			VEL=5, //vel
			SHOOT_ANG_DIAP=6,
			SHOOT_ANG_SHIFT=7,
			SHOOT_ATTACKS=8,
			SHOOT_WARMUP=9,
			SHOOT_COOLDOWN=10,
			SHOOT_LATENCY=11
		};
	};
	
	struct OSPECATTR{
		enum OBJECT_MOD_ATTR:int{
			ATTACKABLE=1
		};
	};
	
	struct OMODTYPE{
		enum OBJECT_MOD_ATTR:int{ //used in macro in npc apply
			ADD=1, //increase by value
			MUL=2, //increase by (value*100)%100 percent
			MAX=3
			//smth else?
		};
	};
	
	struct obj_mod{
		float value;
		int type; //addition, mul or etc
		int attr; //helth, armor, damage, speed or etc
	};
	using obj_spec=obj_mod;
	
	struct object{
		int id;
		short kind;
		short type;
		int cost;
		pointi offset;
		struct {
			std::vector<int> weapon; //id of weapon in hands
		} deps;  //object dependencies
		std::vector<obj_mod> mods;
		std::vector<obj_spec> specs;
		///----------
		object();
		void init_attrs();
		template<class T>
			T& attr_on(int a){return *((T*)((char*)this+a));}
		
		static std::unordered_map<int, std::string> attr_map;
		static std::unordered_map<int, int> attr_type;
//		static object_initializer initializer;
		static std::unordered_map<int, object*> all;
	};
	
	struct object_initializer : object {
		object_initializer();
		~object_initializer();
	};

}

#endif