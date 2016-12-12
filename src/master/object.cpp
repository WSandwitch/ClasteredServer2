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
}

namespace master{

	std::unordered_map<int, object*> object::all;	
	typeof(object::attr_map) object::attr_map;
	typeof(object::attr_type) object::attr_type;
	object_initializer object::initializer;
	
	int o_type(char &c){return 1;}
	int o_type(short &c){return 2;}
	int o_type(int &c){return 3;}
	int o_type(float &c){return 4;}
	int o_type(std::string &c){return 5;}
	int o_type(std::vector<char> &c){return 6;}
	int o_type(std::vector<short> &c){return 7;}
	int o_type(std::vector<int> &c){return 8;}
	int o_type(std::vector<float> &c){return 9;}
	
	object::object(){
	}

#define add_attr(a) \
	do{\
		attr_map[(size_t)&this->a-(size_t)this]=#a;\
		attr_type[(size_t)&this->a-(size_t)this]=o_type(a);\
	}while(0)
	
	void object::init_attrs(){
		add_attr(id);
		add_attr(type);
	}
#undef add_attr
	
	object_initializer::object_initializer(){
		object $;
		$.init_attrs();
		YAML::Node config = YAML::LoadFile("data/objects.yml");
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
		}
//		exit(0);
	}
	
	object_initializer::~object_initializer(){
		for(auto i: all){
			delete i.second;
		}
	}
		
}
