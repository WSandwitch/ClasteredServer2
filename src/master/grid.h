#ifndef CLASTERED_SERVER_GRID_HEADER
#define CLASTERED_SERVER_GRID_HEADER

#include <map>
#include <unordered_map>
#include <vector>

extern "C" {

	typedef 
	struct server_area{
		float l,t,r,b;
	} server_area, server_area_t;

}

namespace master {
	namespace special {
		struct data_cell{
			int owner;
			std::vector<int> shares;
		};
		
		struct grid_server{
			int id, index;
			server_area area;
		};

		class grid_ {
			public:
				float cell[2]; //size of cell in units
				std::unordered_map<int, grid_server> servers;

				grid_(int s[2], int o);
				~grid_();
				void setId(int id);
				bool add_server(int id, bool rec=1);
				bool remove_server(int id, bool rec=1);
				bool reconfigure();
				int get_owner(const float x, const float y);
				std::vector<int>& get_shares(const float x, const float y);//return array of int of different size
			private:
				int id;
				int offset;
				int size[2]; //size of grid in units
				int grid_size[2]; //size of grid in cells
				data_cell** data; //grid
				std::vector<int> server_ids; //ids of server, sorted
				std::map<data_cell, data_cell*> cells; //all cells used in grid
				
				int to_grid(int x, int y);
		};
		
		struct grid_map{
			int size[2];
		};
		
		class grid {
			public:
				float cell[2]; //size of cell in units
				std::unordered_map<int, grid_*> grids;

				grid();
				~grid();
				bool add_server(int id, bool rec=1);
				bool remove_server(int id, bool rec=1);
				bool add_map(int id, int s[2], int o);
				bool remove_map(int id);
				int get_owner(const float x, const float y, int id=0);
				std::vector<int>& get_shares(const float x, const float y, int id=0);//return array of int of different size
			private:
				std::vector<int> server_ids; //ids of server, sorted
				std::vector<int> shares_; 
		};
		
		
	}
}


#endif
