#ifndef CLASTERED_SERVER_SLAVE_NPC_ATTAKS_HEADER
#define CLASTERED_SERVER_SLAVE_NPC_ATTAKS_HEADER

#include "../npc.h"

namespace share{
	class npc;
	
	class npc_shoots: npc{
		public:
			npc_shoots();
		private:
			void shoot0(typeof(point::x) x, typeof(point::y) y);
			void shoot1(typeof(point::x) x, typeof(point::y) y);///bullet
			void shoot2(typeof(point::x) x, typeof(point::y) y);
	};
}	

#endif
