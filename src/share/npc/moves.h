#pragma once

#include "../npc.h"

namespace share{
	class npc;
	
	class npc_moves: npc{
		public:
			npc_moves();

		private:
			void move0(typeof(point::x) x, typeof(point::y) y);
			void move1(typeof(point::x) x, typeof(point::y) y);///bullet move (move straight until border or enemy and suicide after it)
			void move2(typeof(point::x) x, typeof(point::y) y);///bullet move reckochet (move to the same position as target npc)
			void move3(typeof(point::x) x, typeof(point::y) y);///stiky move (move to the same position as target npc)
	};
}	

