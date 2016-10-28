#ifndef CLASTERED_SERVER_PACKET_HEADER
#define CLASTERED_SERVER_PACKET_HEADER

#include <vector>
#include <cstdio>
#include <string>

extern "C"{
	
}

namespace share {
	
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
	};
	
	class packet {
		public:
			std::vector<packet_chank> chanks;
			struct{
				char type;
				int id;
			} dest;
			
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
		private: 
			std::vector<char> buf;
			
			void parse();
	};
}


#endif
