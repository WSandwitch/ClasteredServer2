#pragma once

#include <unordered_map>
#include <list>
#include <queue>
#include <vector>

#include "npc.h"
#include "math/segment.h"

#pragma GCC diagnostic ignored "-Wwrite-strings"

extern "C"{

}

namespace share {
	class npc;
	
	struct cell{
		int id;
		mutex m;
		std::unordered_map<int, npc*> npcs;
		std::vector<segment*> segments;
	};

	class map {
		public:
			int id;
			point source;
			pointi size;
			point cell;
//			share::cell *grid;
			std::vector<share::cell> grid;
			std::vector<segment*> segments;
			std::unordered_map<int, quad> safezones;
			int map_size[2];
			int offset;
			std::string name;
		
			map(char *path="../maps/map.tmx");
			~map();
			share::cell* cells(int id);
			share::cell* cells(point &p);
			share::cell* cells(typeof(point::x) x, typeof(point::y) y);
			std::list<int> cells(point &l, float r);
			std::list<int> cells(point &&l, point &&b);
			std::list<int> cells(typeof(point::x) l, typeof(point::y) t, typeof(point::x) r, typeof(point::y) b);
			int to_grid(typeof(point::x) x, typeof(point::y) y);
			int to_grid_x(typeof(point::x) x);
			int to_grid_y(typeof(point::y) y);
			int id_to_x(int id);
			int id_to_y(int id);
			void reconfigure(char* path);
			std::vector<segment> cell_borders(int id);
			std::list<int> near_cells(int id, typeof(npc::r) r);
			std::list<int> near_cells(typeof(point::x) x, typeof(point::y) y, typeof(npc::r) r);
			int nearest_safezone_id(point& p);
			quad& nearest_safezone(typeof(point::x) x, typeof(point::y) y);
			quad& nearest_safezone(point& p);
			
			static int getId(char* s);
			
			friend std::ostream& operator<<(std::ostream &stream, const map &m);
		private:
			void clean_segments();
	};
	
}


