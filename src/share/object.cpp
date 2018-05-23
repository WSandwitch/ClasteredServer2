#include <cstdlib>
#include <cstdio>

#include "yaml-cpp/yaml.h"
#include "object.h"

namespace YAML{
	
	template<class T>
		std::vector<T> vec_of(const YAML::Node &n){
			std::vector<T> v;
			for(YAML::Node e: n){ //!!need to check for error
				v.push_back(e.as<T>());
			}
			return v;
		}
	
	template<class T>
		std::vector<std::vector<T>> vec_vec_of(const YAML::Node &n){
			std::vector<std::vector<T>> v;
			for(YAML::Node e: n){ //!!need to check for error
				v.push_back(e.as<std::vector<T>>());
			}
			return v;
		}
	
	template <>
		share::obj_mod Node::as() const{
			share::obj_mod $={0};
			YAML::Node node;
			if (IsMap()){
				node=this->operator[]("value");
				if (node.IsScalar())
					$.value=node.as<typeof($.value)>();
				node=this->operator[]("type");
				if (node.IsScalar())
					$.type=node.as<typeof($.type)>();
				node=this->operator[]("attr");
				if (node.IsScalar())
					$.attr=node.as<typeof($.attr)>();
//				printf("got %g %d %d\n", $.value, $.type, $.attr);
			}
			return $;
		}
	template <>
		std::vector<share::obj_mod> Node::as() const{
			return vec_of<share::obj_mod>(*this);
		}
	template <>
		std::vector<char> Node::as() const{
			return vec_of<char>(*this);
		}
	template <>
		std::vector<short> Node::as() const{
			return vec_of<short>(*this);
		}
	template <>
		std::vector<int> Node::as() const{
			return vec_of<int>(*this);
		}
	template <>
		std::vector<float> Node::as() const{
			return vec_of<float>(*this);
		}

	template <>
		std::vector<std::vector<char>> Node::as() const{
			return vec_vec_of<char>(*this);
		}
	template <>
		std::vector<std::vector<short>> Node::as() const{
			return vec_vec_of<short>(*this);
		}
	template <>
		std::vector<std::vector<int>> Node::as() const{
			return vec_vec_of<int>(*this);
		}
	template <>
		std::vector<std::vector<float>> Node::as() const{
			return vec_vec_of<float>(*this);
		}

}

namespace share{

	
	std::unordered_map<int, object*> object::all;	
	typeof(object::attr_map) object::attr_map;
	typeof(object::attr_type) object::attr_type;
//	object_initializer object::initializer;
	
	int o_type(char &c){return 1;}
	int o_type(short &c){return 2;}
	int o_type(int &c){return 3;}
	int o_type(float &c){return 4;}
	int o_type(std::string &c){return 5;}
	int o_type(std::vector<char> &c){return 6;}
	int o_type(std::vector<short> &c){return 7;}
	int o_type(std::vector<int> &c){return 8;}
	int o_type(std::vector<float> &c){return 9;}
	int o_type(std::vector<std::vector<char>> &c){return 10;}
	int o_type(std::vector<std::vector<short>> &c){return 11;}
	int o_type(std::vector<std::vector<int>> &c){return 12;}
	int o_type(std::vector<std::vector<float>> &c){return 13;}
	int o_type(std::vector<obj_mod> &c){return 14;}
	
	object::object(){
	}

#define add_attr(a) \
	do{\
		attr_map[(size_t)&this->a-(size_t)this]=#a;\
		attr_type[(size_t)&this->a-(size_t)this]=o_type(a);\
	}while(0)
	
	void object::init_attrs(){
		add_attr(id);
		add_attr(kind); 
		add_attr(type);
		add_attr(cost); 
		add_attr(deps.weapon); 
		add_attr(mods); 
		add_attr(offset.x); 
		add_attr(offset.y); 
	}
#undef add_attr
	
	object_initializer::object_initializer(){
		object $;
		$.init_attrs();
		YAML::Node config = YAML::LoadFile("../data/objects.yml");
		//get original attrs
		if (config.IsSequence()){
			for (auto e: config){
				object *o=new object();
				for (auto am: attr_map){
					auto type=attr_type[am.first];
					if(YAML::Node &&attr=e[am.second]){
						switch(type){
							case 1: 
								if (attr.IsScalar()){
									o->attr_on<char>(am.first)=attr.as<char>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<char>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 2: 
								if (attr.IsScalar()){
									o->attr_on<short>(am.first)=attr.as<short>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<short>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 3: 
								if (attr.IsScalar()){
									o->attr_on<int>(am.first)=attr.as<int>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 4: 
								if (attr.IsScalar()){
									o->attr_on<float>(am.first)=attr.as<float>();
//										printf("%s: %g\n", am.second.data(), o->attr_on<float>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 5:
								o->attr_on<std::string>(am.first)=attr.as<std::string>();
//								printf("%s: %s\n", am.second.data(), o->attr_on<std::string>(am.first).data());
								break;
							case 6: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<char>>(am.first)=attr.as<std::vector<char>>();
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 7: if (config.IsSequence()){
								o->attr_on<std::vector<short>>(am.first)=attr.as<std::vector<short>>();
								break;
							}else
								printf("object %d attr %s type error\n", o->id, am.second.data());
							case 8: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<int>>(am.first)=attr.as<std::vector<int>>();
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 9: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<float>>(am.first)=attr.as<std::vector<float>>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 10: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<std::vector<char>>>(am.first)=attr.as<std::vector<std::vector<char>>>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 11: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<std::vector<short>>>(am.first)=attr.as<std::vector<std::vector<short>>>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 12: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<std::vector<int>>>(am.first)=attr.as<std::vector<std::vector<int>>>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 13: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<std::vector<float>>>(am.first)=attr.as<std::vector<std::vector<float>>>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
							case 14: 
								if (attr.IsSequence()){
									o->attr_on<std::vector<obj_mod>>(am.first)=attr.as<std::vector<obj_mod>>();
//									printf("%s: %d\n", am.second.data(), o->attr_on<int>(am.first));
								}else
									printf("object %d attr %s type error\n", o->id, am.second.data());
								break;
						}
					}
				}
//				printf("got id:%d, type:%d\n", o->id, o->type);
//				printf("got vf:%g,%g\n", o->vf[0], o->vf[1]);
//				printf("got vs:%hd,%hd\n", o->vs[0], o->vs[1]);
				if (!all.count(o->id))
					all[o->id]=o;
				else
					delete o;
			}
			try{all.at(0);}catch(...){all[0]=new object();} //set empty object
		}else{
			printf("couldn't read objects\n");
		}
/*		//convert attrs
		for(auto ei: all){
			auto e=ei.second;
			//convert to pdegrees
			e->weapon.ang_diap=to_pdegrees(e->weapon.ang_diap);
			e->weapon.ang_shift=to_pdegrees(e->weapon.ang_shift);
			//convert to tikc
			e->weapon.warmup=e->weapon.warmup>0 ? NPC_FULL_TEMP/(w.tps*e->weapon.warmup) : 0;
			e->weapon.cooldown=e->weapon.cooldown>0 ? NPC_FULL_TEMP/(w.tps*e->weapon.cooldown) : 0;
			e->weapon.latency=e->weapon.latency>0 ? NPC_FULL_TEMP/(w.tps*e->weapon.latency) : 0;
		}
*///		exit(0);
	}
	
	object_initializer::~object_initializer(){
		for(auto i: all){
			delete i.second;
		}
	}
		
}
