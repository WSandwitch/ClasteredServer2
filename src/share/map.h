#ifndef CLASTERED_SERVER_SLAVE_MAP_HEADER
#define CLASTERED_SERVER_SLAVE_MAP_HEADER

#include <map>
#include <list>
#include <queue>
#include <vector>

#include "npc.h"
#include "math/segment.h"


extern "C"{

}

namespace share {
	class npc;
	
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
			share::cell *grid;
			std::vector<segment*> segments;
			int map_size[2];
			int offset;
		
			map(int x=10, int y=10);
			~map();
			share::cell* cells(int id);
			share::cell* cells(point &p);
			share::cell* cells(typeof(point::x) x, typeof(point::y) y);
			std::list<int> cells(typeof(point::x) l, typeof(point::y) t, typeof(point::x) r, typeof(point::y) b);
			int to_grid(typeof(point::x) x, typeof(point::y) y);
			int to_grid_x(typeof(point::x) x);
			int to_grid_y(typeof(point::y) y);
			int id_to_x(int id);
			int id_to_y(int id);
			void reconfigure();
			std::vector<segment> cell_borders(int id);
			std::list<int> near_cells(int id, typeof(npc::r) r);
			std::list<int> near_cells(typeof(point::x) x, typeof(point::y) y, typeof(npc::r) r);
			
			friend std::ostream& operator<<(std::ostream &stream, const map &m);
		private:
			void clean_segments();
	};
}


#endif
