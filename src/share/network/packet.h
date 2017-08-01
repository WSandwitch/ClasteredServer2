#ifndef CLASTERED_SERVER_PACKET_HEADER
#define CLASTERED_SERVER_PACKET_HEADER

#include <vector>
#include <cstdio>
#include <string>

extern "C"{
	
}

namespace share {
	class packet;
	
	typedef bool (packet::*add_func)(void*);
	
	class packet_chank{
		public:
			char type;
			union{
				char c;
				short s;
				int i;
				float f;
				double d;
			}value;
			std::string str;
		
			int size();
			void* data();
			FILE* stream();
			template<class T> 
				int size_func();
			int size_func_str();
			template<typename T> 
				void* data_func();
	};
	
	class packet {
		public:
			std::vector<packet_chank> chanks;
			
			packet();
//			~packet();
			void setType(char);
			char type();
			int size();
			void resize(int s);
			void* data();
			FILE* stream();
			bool init();
			bool init(void*, short);
			bool add(char);
			bool add(short);
			bool add(int);
			bool add(float);
			bool add(double);
			bool add(std::string);
			bool add(char*, short);
			bool add(void*, short size);
			bool add(short type, void* data);
			template<class T> 
				bool add(void*);
			template<class T>
				bool operator<<(T o){return add(o);}
				
			static add_func add_funcs[6];
		private: 
			std::vector<char> buf;
			
			void parse();
	};
}


#endif
