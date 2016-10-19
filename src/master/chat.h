#ifndef CHAT_HEADER
#define CHAT_HEADER

#include <list>
#include <map>

#include "client.h"
#include "../share/system/mutex.h"

typedef share::mutex t_mutex_t;

namespace master {
	struct chat{
		int id;
		std::map<int, void*> clients;
		t_mutex_t mutex;
		std::list<void*> history;
	};


	void chatsInit();
	void chatsClear();

	chat* chatNew();
	void chatClear(chat* c);

	void chatClientsAdd(chat* c, void* client);
	void* chatClientsGet(chat* c, int id);
	void chatClientsRemove(chat* c, void* client);

	int chatsAdd(chat* c);
	chat* chatsGet(int id);
	void chatsRemove(chat* c);
	void chatsCheck();
}
#endif
