#ifndef CLASTERED_SERVER_SLAVE_OBJECT_HEADER
#define CLASTERED_SERVER_SLAVE_OBJECT_HEADER

#include <vector>
#include <string>
#include <unordered_map>

namespace share{

	int o_type(char &c);
	int o_type(short &c);
	int o_type(int &c);
	int o_type(float &c);
	int o_type(std::string &c);
	int o_type(std::vector<char> &c);
	int o_type(std::vector<short> &c);
	int o_type(std::vector<int> &c);
	int o_type(std::vector<float> &c);

	struct object_initializer;

	struct object{
		int id;
		short type;

		object();
		void init_attrs();
		template<class T>
			T& attr_on(int a){return *((T*)((char*)this+a));}
		
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