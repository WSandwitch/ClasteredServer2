#ifndef STORAGE_HEADER
#define STORAGE_HEADER


namespace master {
	struct slave_info{
		char host[40];
		short port;
	};

	struct user_info{
		int id;
		char login[40];
		char name[40];
		char passwd[50];
	};

	struct storage_config{
		char file[100];
	};

	//provided by main
	
	int storageInit(storage_config*);
	int storageClear();

	int storageSlaves(int(*f)(slave_info*,void*arg), void*arg);
	int storageSlaveSetBroken(char *host, short port);
	int storageSlaveSetUnbroken(char *host, short port);

	int storageUsers(int(*f)(user_info*,void*arg),void*arg);
	int storageUserById(int id, user_info* u);
	int storageUserByLogin(char *login, user_info* u);

	int storageAttributeGet(int id, const char* k, char* out);
	int storageAttributeSet(int id, const char* k, const char* v);

	int storageAttributesGet(int id, char** k, char** out, short size);
	int storageAttributesForEach(int id, char** ks, short size, void*(f)(char* k,char*v, void*arg), void*arg);
	int storageAttributesSet(int id, char** k, char** v, short size);
}
#endif