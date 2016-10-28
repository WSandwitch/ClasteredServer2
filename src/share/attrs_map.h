#ifndef CLASTERED_SERVER_SLAVE_ATTRS_MAP_HEADER
#define CLASTERED_SERVER_SLAVE_ATTRS_MAP_HEADER

#include <vector>
#include <unordered_map>

#define map_cont std::unordered_map
//for npc attributes
namespace share {

	class attrs_map{
		public:
			attrs_map(): _size(0) {
			};
			template<class T> 
				void push_back(T& attr){
					attr_size[_size]=sizeof(attr);
					attr_shift[_size]=&attr;
					shift_attr[&attr]=_size;
					_size++;
				};
			void* operator()(char id){
				return attr_shift[id];
			};
			char operator()(void* attr){
				return shift_attr[attr];
			};
			unsigned short size(){
				return attr_size.size();
			};
			unsigned short size(char id){
				return attr_size[id];
			};
			unsigned short size(void* attr){
				return attr_size[operator()(attr)];
			};
			
		private:
			char _size;//max 250 elements
			map_cont<char, unsigned short> attr_size;
			map_cont<char, void*> attr_shift;
			map_cont<void*, char> shift_attr;	
	};
}
#undef map_cont

#endif
