#ifndef CLASTERED_SERVER_SLAVE_ATTRS_MAP_HEADER
#define CLASTERED_SERVER_SLAVE_ATTRS_MAP_HEADER

#include <vector>
#include <unordered_map>

#include "get_type.h"

#define map_cont std::unordered_map
//for npc attributes
namespace share {
	class attrs_map;
	
	class attrs_map{
		private:
			char _size;//max 250 elements
			char *base;
			map_cont<char, unsigned short> attr_size;
			map_cont<char, int> attr_shift;
			map_cont<int, char> shift_attr;	
			map_cont<int, char> attr_type;	
		
		public:
			attrs_map():_size(1), base(0){};
			attrs_map(attrs_map &a):_size(1), base(0){};//can't be copyed
			void set_base(void* b){base=(char*)b;};
			void clear(){_size=1;};
			template<class T> 
				char push_back(T& attr){
					int shift=(size_t)&attr-(size_t)base;
					attr_size[_size]=sizeof(attr);
					attr_shift[_size]=shift;
					attr_type[shift]=get_type(attr);
					shift_attr[shift]=_size;
					return _size++;
				};
			void* operator()(char id){
				try{
					return base+attr_shift.at(id);
				}catch(...){
					return 0;
				}
			};
			char operator()(void* attr){
				try{
					return shift_attr.at((size_t)attr-(size_t)base);//TODO:faster cast
				}catch(...){
					return 0;
				}
			};
			char type(void* attr){
				try{
					return attr_type.at((size_t)attr-(size_t)base);
				}catch(...){
					return 0;
				}
			};
			unsigned short size(){
				return attr_size.size();
			};
			unsigned short size(char id){
				try{
					return attr_size.at(id);
				}catch(...){
					return 0;
				}
			};
			unsigned short size(void* attr){
				try{
					return attr_size.at(operator()(attr));
				}catch(...){
					return 0;
				}
			};
			typeof(attr_shift.begin()) begin(){
				return attr_shift.begin();
			};
			typeof(attr_shift.end()) end(){
				return attr_shift.end();
			};			
	};
}
#undef map_cont

#endif
