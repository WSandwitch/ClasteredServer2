#ifndef CLASTERED_SERVER_SLAVE_MAP_HEADER
#define CLASTERED_SERVER_SLAVE_MAP_HEADER

#include <map>
#include <queue>
#include <vector>

#include "lib/grid.h"
#include "npc.h"
#include "player.h"
#include "segment.h"


extern "C"{

}

namespace clasteredServerSlave {

	struct cell{
		int id;
		std::map<int, npc*> npcs;
		std::vector<segment*> segments;
		npc* get_npc(int id);
		void add_npc(npc *n);
	};

	class map {
		public:
			point source;
			pointi size;
			point cell;
			clasteredServerSlave::cell *grid;
			std::vector<segment*> segments;
			
			map(int x, int y);
			~map();
			clasteredServerSlave::cell* cells(int id);
			clasteredServerSlave::cell* cells(point &p);
			clasteredServerSlave::cell* cells(typeof(point::x) x, typeof(point::y) y);
			std::vector<int> cells(typeof(point::x) l, typeof(point::y) t, typeof(point::x) r, typeof(point::y) b);
			int to_grid(typeof(point::x) x, typeof(point::y) y);
			int to_grid_x(typeof(point::x) x);
			int to_grid_y(typeof(point::y) y);
			int id_to_x(int id);
			int id_to_y(int id);
			void reconfigure();
			std::vector<segment> cell_borders(int id);
			std::vector<int> near_cells(int id, typeof(npc::r) r);
			std::vector<int> near_cells(typeof(point::x) x, typeof(point::y) y, typeof(npc::r) r);
			
			friend std::ostream& operator<<(std::ostream &stream, const map &m);
		private:
			void clean_segments();
	};
}


#endif
