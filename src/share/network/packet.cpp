#include <cstdio>

#include "packet.h"
#include "bytes_order.h"

extern "C"{
#include <string.h>
#include <unistd.h>
}

#define MAX_SIZE (32000)

/*
╔══════════════════════════════════════════════════════════════╗
║ functions for work with sockets 			                       ║
║ created by Dennis Yarikov						                       ║
║ aug 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace share {
	
	typedef int (packet_chank::*size_func_t)();
	typedef void* (packet_chank::*data_func_t)();
	
	template<class T> int packet_chank::size_func(){
		return sizeof(T);
	}
	int packet_chank::size_func_str(){
		return str.size();
	}
	
	static	size_func_t _size_funcs[7]={0, &packet_chank::size_func<char>, &packet_chank::size_func<short>, &packet_chank::size_func<int>, &packet_chank::size_func<float>, &packet_chank::size_func<double>, &packet_chank::size_func_str};
	
	int packet_chank::size(){
		if (type>0 && type<7)
			return (this->*_size_funcs[(short)type])();
		return 0;
	}
	
	template<typename T> void* packet_chank::data_func(){
		return 0;
	}
	template<> void* packet_chank::data_func<char>(){
		return &value.c;
	}
	template<> void* packet_chank::data_func<short>(){
		return &value.s;
	}
	template<> void* packet_chank::data_func<int>(){
		return &value.i;
	}
	template<> void* packet_chank::data_func<float>(){
		return &value.f;
	}
	template<> void* packet_chank::data_func<double>(){
		return &value.d;
	}
	template<> void* packet_chank::data_func<std::string>(){
		return (void*)str.c_str();
	}
	static	data_func_t _data_funcs[7]={0, &packet_chank::data_func<char>, &packet_chank::data_func<short>, &packet_chank::data_func<int>, &packet_chank::data_func<float>, &packet_chank::data_func<double>, &packet_chank::data_func<std::string>}; 
	
	void* packet_chank::data(){
		if (type>0 && type<7)
			return (this->*_data_funcs[(short)type])();
		return 0;
	}
	
/*
	class packet {
		public:
			struct{
				char type;
				int id;
			} dest;

			packet();
//			~packet();
			void setType(char);
			int size();
			void* data();
			bool init();
			bool init(void*, short);
			bool add(char);
			bool add(short);
			bool add(int);
			bool add(float);
			bool add(double);
			bool add(std::string);
			bool add(void*, short size);
		private: 
			std::vector<char> buf;
			std::vector<packet_chank> chanks;
			
			void parse();
	};
*/
	
	packet::packet(){
		init();
	}
	
	int packet::size(){
		return buf.size();
	}
	
	void packet::resize(int s){
		buf.resize(s);
	}
	
	void* packet::data(){
		return buf.data();
	}
	
	FILE* packet::stream(){
		return fmemopen(buf.data(), buf.size(), "r");
	}
	
	bool packet::init(){
		buf.clear();
		buf.push_back(0);
		buf.push_back(0);
		return 0;
	}
	
	bool packet::init(void* _data, short s){
		char* data=(char*)_data;
		buf.clear();
		buf.insert(buf.end(), data, data+s);
		parse();
		return 0;
	}
	
	void packet::setType(char t){
		buf[0]=t;
	}
	
	char packet::type(){
		return buf[0];
	}
	
	bool packet::add(void* _data, short s){
		char* data=(char*)_data;
		if (size()+s>MAX_SIZE)
			return 1;
		buf.insert(buf.end(), data, data+s);
		return 0;
	}
	
	bool packet::add(char a){
		if (size()+sizeof(char)+sizeof(a)>MAX_SIZE)
			return 1;
		buf.push_back(1);
		buf.push_back(a);
		buf[1]=buf[1]+1>125?-1:buf[1]+1;
		return 0;
	}
	
	bool packet::add(short a){
		a=byteSwap(a);
		if (size()+sizeof(char)+sizeof(a)>MAX_SIZE)
			return 1;
		buf.push_back(2);
		buf.insert(buf.end(), (char*)&a, (char*)(&a+1));
		buf[1]=buf[1]+1>125?-1:buf[1]+1;
		return 0;
	}
	
	bool packet::add(int a){
		a=byteSwap(a);
		if (size()+sizeof(char)+sizeof(a)>MAX_SIZE)
			return 1;
		buf.push_back(3);
		buf.insert(buf.end(), (char*)&a, (char*)(&a+1));
		buf[1]=buf[1]+1>125?-1:buf[1]+1;
		return 0;
	}
	
	bool packet::add(float a){
		a=byteSwap(a);
		if (size()+sizeof(char)+sizeof(a)>MAX_SIZE)
			return 1;
		buf.push_back(4);
		buf.insert(buf.end(), (char*)&a, (char*)(&a+1));
		buf[1]=buf[1]+1>125?-1:buf[1]+1;
		return 0;
	}
	
	bool packet::add(double a){
		a=byteSwap(a);
		if (size()+sizeof(char)+sizeof(a)>MAX_SIZE)
			return 1;
		buf.push_back(5);
		buf.insert(buf.end(), (char*)&a, (char*)(&a+1));
		buf[1]=buf[1]+1>125?-1:buf[1]+1;
		return 0;
	}
	
	bool packet::add(std::string a){
		add((char*)a.c_str(), a.size());
		return 0;
	}
	
	bool packet::add(char* data, short s){
		if (size()+sizeof(char)+sizeof(short)+s>MAX_SIZE)
			return 1;
		short size=byteSwap(s);
		buf.push_back(6);
		buf.insert(buf.end(), (char*)&size, (char*)(&size+1));
		buf.insert(buf.end(), data, data+s);
		buf[1]=buf[1]+1>125?-1:buf[1]+1;
		return 0;
	}
	
	template<class T>
		bool packet::add(void *data){
			return add(*(T*)data);
		}
		
	add_func packet::add_funcs[6]={0, &packet::add<char>, &packet::add<short>, &packet::add<int>, &packet::add<float>, &packet::add<double>};
		
	bool packet::add(short type, void* data){
		if (type>0 && type<6)
			return (this->*packet::add_funcs[type])(data);
		return add((char)0);
	}
	
	void packet::parse(){
		char* buf=(char*)data();
		int s=size();
		chanks.clear();
		for(int i=2;i<s-1;){//TODO: find why mesage have nonpared type
			packet_chank chank;
			chank.type=buf[i];
			switch(chank.type){
				case 1:{
					chank.value.c=buf[(++i)++];
					chanks.push_back(chank);
					break;
				}
				case 2:{
					memcpy(&chank.value.s, &buf[++i], sizeof(chank.value.s));
					chank.value.s=byteSwap(chank.value.s);
					i+=sizeof(chank.value.s);
					chanks.push_back(chank);
					break;
				}
				case 3:{
					memcpy(&chank.value.i, &buf[++i], sizeof(chank.value.i));
					chank.value.i=byteSwap(chank.value.i);
					i+=sizeof(chank.value.i);
					chanks.push_back(chank);
					break;
				}
				case 4:{
					memcpy(&chank.value.f, &buf[++i], sizeof(chank.value.f));
					chank.value.f=byteSwap(chank.value.f);
					i+=sizeof(chank.value.f);
					chanks.push_back(chank);
					break;
				}
				case 5:{
					memcpy(&chank.value.d, &buf[++i], sizeof(chank.value.d));
					chank.value.d=byteSwap(chank.value.d);
					i+=sizeof(chank.value.d);
					chanks.push_back(chank);
					break;
				}
				case 6:{
					short $;
					memcpy(&$, &buf[++i], sizeof($));
					$=byteSwap($);
					i+=sizeof($);
					chank.str.assign(&buf[i], $);
					i+=$;
					chanks.push_back(chank);
					break;
				}
			}
		}
	}
	
}