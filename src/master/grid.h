#ifndef CLASTERED_SERVER_GRID_HEADER
#define CLASTERED_SERVER_GRID_HEADER

#include <map>

extern "C" {

typedef 
struct server_area{
	float l,t,r,b;
} server_area, server_area_t;

}

namespace master {
	struct data_cell{
		int owner;
		std::vector<int> shares;
	};
	
	struct server{
		int id, index;
		server_area area;
	};

	class grid {
		public:
			float cell[2]; //size of cell in units
			std::map<int, server> servers;

			grid(float s[2], float o);
			~grid();
			void setId(int id);
			bool add(int id, bool rec=1);
			bool remove(int id, bool rec=1);
			int getOwner(const float x, const float y);
			std::vector<int>& getShares(const float x, const float y);//return array of int of different size
		private:
			int id;
			float offset;
			float size[2]; //size of grid in units
			int grid_size[2]; //size of grid in cells
			data_cell** data; //grid
			std::vector<int> server_ids; //ids of server, sorted
			std::map<data_cell, data_cell*> cells; //all cells used in grid
			
			int to_grid(int x, int y);
			bool reconfigure();
	};
}


#endif
