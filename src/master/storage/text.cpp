#ifdef STORAGE_TEXT

#include <list>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../share/system/log.h"
#include "../../share/crypt/crc32.h"
#include "../storage.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 		text files storage implementation, used for testing 			                       ║
║ created by Dennis Yarikov						                       ║
║ jul 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

#define SLAVES_FILE_DEFAULT "../storage/slaves.txt"
#define USERS_FILE_DEFAULT "../storage/users.txt"
	namespace master {
	struct files_config {
		char users[100];
		char slaves[100];
		char attributes[100];
	};

	static files_config files;

	#define getUserInfo(f, u) ({ short $;\
			$=fscanf(f, "%d %s %s ", &(u)->id, (u)->login, (u)->passwd);\
			if ($==3){\
				int $str=sizeof((u)->name);\
				char *str=(char*)malloc($str);\
				if (str){\
					short $$str=getline(&str,(size_t*)&$str,f);\
					if (str[($$str<$str ? $$str : $str)-1]=='\n') str[($$str<$str ? $$str : $str)-1]=0;\
					sprintf((u)->name, "%s", str);\
					free(str);\
				}\
			}\
		$;})

	int storageInit(storage_config* conf){
		FILE* f;
		if (conf->file[0]!=0 && ((f=fopen(conf->file, "rt"))!=0)){
			while(feof(f)==0){
				char buf[100], $[100];
				fscanf(f,"%s",buf);
				if (strcmp(buf,"users_file")==0){
					fscanf(f, "%s", $);
					sprintf(files.users, "../%s", $);
				}else
				if (strcmp(buf,"slaves_file")==0){
					fscanf(f, "%s", $);
					sprintf(files.slaves, "../%s", $);
				}
				if (strcmp(buf,"attributes_path")==0){
					fscanf(f, "%s", $);
					sprintf(files.attributes, "../%s", $);
				}
			}
			fclose(f);
			return 0;
		}
		//storageConfigParse(&files);
		//TODO: change
		printf("can open storage config file %s, using defaults\n", conf->file);
		sprintf(files.slaves,"%s",SLAVES_FILE_DEFAULT);
		sprintf(files.users,"%s",USERS_FILE_DEFAULT);
		return 1;
	}

	int storageClear(){
		return 0;
	}

	int storageSlaves(int(*$)(slave_info*,void*arg),void*arg){
		FILE *f=fopen(files.slaves,"rt");
		slave_info s;
		int i=0;
		if (f){
			while(feof(f)==0){
				i++;
				memset(&s,0,sizeof(s));
				if (fscanf(f,"%s %hd\n", s.host, &s.port)!=2){
					printf("error in %s on line %d\n", files.slaves, i);
					continue;
				}

				$(&s, arg);
			}
			fclose(f);
			return 0;
		}
		perror("fopen");
		return 1;
	}

	int storageSlaveSetBroken(char *host, short port){
		return 0;
	}

	int storageSlaveSetUnbroken(char *host, short port){
		return 0;
	}

	int storageUsers(int(*$)(user_info*,void*arg),void*arg){
		FILE *f=fopen(files.users,"rt");
		user_info u;
		if (f){
			while(feof(f)==0){
				memset(&u,0,sizeof(u));
				if (getUserInfo(f, &u)==3){
					$(&u, arg);
				}
			}
			fclose(f);
			return 0;
		}
		perror("fopen");
		return 1;
	}

	int storageUserById(int id, user_info* u){
		FILE *f=fopen(files.users,"rt");
		if (f){
			while(feof(f)==0){
				getUserInfo(f, u);
				if (u->id==id){
					printf("user with id %d found\n", id);
					break;
				}
			}
			fclose(f);
			if (u->id==id)
				return 0;
			printf("user with id %d not found\n", id);
			memset(u,0,sizeof(*u));
			return -1;
		}
		perror("fopen");
		return 1;
	}

	int storageUserByLogin(char* login, user_info* u){
		short $=0;
		FILE *f=fopen(files.users,"rt");
		if (f){
			while(feof(f)==0){
				getUserInfo(f, u);
				
				sprintf(u->login, "%s", login);//fake auth for testing
				sprintf(u->passwd, "%s", login);//fake auth for testing
				u->id=share::crc32(u->login, strlen(u->login));//fake auth for testing
				
				if (strcmp(u->login,login)==0){
					printf("user with login %s found\n", login);
					$=1;
					break;
				}
			}
			fclose(f);
			if ($)
				return 0;
			printf("user with login %s not found\n", login);
			memset(u,0,sizeof(*u));
			return -1;
		}
		perror("fopen");
		return 1;
	}

	int storageAttributeGet(int id, const char* k, char* out){
		short $=0;
		FILE *f=0;
		char path[50];
		sprintf(path, "%s/%d.cfg", files.attributes, id);
		if ((f=fopen(path,"rt"))!=0){
			char key[100], *buf;
			while(feof(f)==0){
				size_t $buf=sizeof(key);
				if ((buf=(char*)malloc($buf))!=0){
					if (fscanf(f, "%s ", key)==1){
						if (strcmp(k, key)==0){
							int $$buf=getline(&buf,&$buf,f);
							if (buf[$$buf-1]=='\n')
								buf[$$buf-1]=0;
							sprintf(out, "%s", buf);
							printf("user attribute %s found: %s\n", k, out);
							$=1;
							break;
						}
					}
					free(buf);
				}
			}
			fclose(f);
			if ($)
				return 0;
		}
		out[0]=0;
		return 1;
	}

	struct element{
		char key[100]; 
		char value[1000];
	};

	int storageAttributeSet(int id, const char* k, const char* v){
		char path[50], *buf;
		FILE *f=0;
		std::list<element*> l;
		element *e;
		short updated=0;
		sprintf(path, "%s/%d.cfg", files.attributes, id);
		if ((f=fopen(path,"rt"))!=0){
			while(feof(f)==0){
				size_t $buf=sizeof(path);
				if ((buf=(char*)malloc($buf))!=0){
					if ((e=(element*)malloc(sizeof(*e)))!=0){
						if (fscanf(f, "%s ", e->key)==1){
							int $$buf=getline(&buf,&$buf,f);
							if (buf[$$buf-1]=='\n')
								buf[$$buf-1]=0;
							sprintf(e->value, "%s", buf);
							if (strcmp(k, e->key)==0){
								sprintf(e->value,"%s", v);
								updated=1;
							}
							l.push_back(e);
						}
					}
					free(buf);
				}
			}	
			fclose(f);
		} else
			return -1;
		if (!updated){
			if ((e=(element*)malloc(sizeof(*e)))!=0){
				sprintf(e->key,"%s", k);
				sprintf(e->value,"%s", v);
				l.push_back(e);
			}
		}
		if ((f=fopen(path,"wt"))!=0){
			for (auto el:l){
				printf("write %s %s\n", el->key, el->value);
				fprintf(f, "%s %s\n", el->key, el->value);
			}
			return 0;
		}
		return 1;
	}

	int storageAttributesGet(int id, char** k, char** out, short size){
		int i;
		for(i=0;i<size;i++){
			storageAttributeGet(id,k[i],out[i]);
		}
		return 0;
	}

	int storageAttributesForEach(int id, char** ks, short size, void*(f)(char* k,char*v, void*arg), void*arg){
		int i;
		char buf[100];
		for(i=0;i<size;i++){
			storageAttributeGet(id,ks[i],buf);
			f(ks[i],buf,arg);
		}
		return 0;
	}

	int storageAttributesSet(int id, char** k, char** v, short size){
		int i;
		for(i=0;i<size;i++){
			storageAttributeSet(id,k[i],v[i]);
		}
		return 0;
	}
}
#endif