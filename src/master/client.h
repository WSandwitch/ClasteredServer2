#ifndef CLIENT_HEADER
#define CLIENT_HEADER

#include <list>
#include <map>
#include <string>
#include <sys/time.h>

#include "storage.h"
#include "chat.h"
#include "../share/system/time.h"
#include "../share/system/mutex.h"
#include "../share/network/socket.h"
#include "../share/network/packet.h"

#define CLIENT_CONN_SOCKET 1
#define MSG_CLIENT 1

using namespace share;

namespace master {
	
	struct client_message {
	//	packet packet;
		char * data;
		short $data;
		share::mutex mutex;
		int num;
		short ready;
		
		client_message(void* buf, short size);
		~client_message();
	};
	
	class client{
		public:
			int id;
			char name[40];
			char login[40];
			char passwd[40];
			
			short conn_type;
			short broken;
			int server_id;
			share::socket* sock;
			share::mutex mutex;
			std::list<client_message> messages;
			std::map<int, void*> chats;
			timestamp_t timestamp;
			char token[30];
			
			client(share::socket* sock);
			~client();
			int proceed(packet& p);
			void messagesAdd(client_message *m);
			void messages_proceed();
			void set_info(user_info *u);
			void	server_clear();
		
			static share::mutex m;
			static std::map<int, client> all;
		
			static void add(client& c);
			static void get(int id);
			static void remove(int id);
			static void check();
	};


	void clientsInit();
	void clientsClear();

	client* clientNew(share::socket *sock);
	void clientClear(client* c);

	//work with clients container
	int clientsAdd(client* c);
	client* clientsGet(int id);
	void clientsRemove(client* c);
	void clientsCheck();

	//processor for packet from client
	int clientPacketProceed(client *c, packet* p);

	//work with client message queue
	void clientMessagesAdd(client *c, client_message *m);
	client_message* clientMessageNew(void* buf, short size);
	void clientMessageClear(client_message* m);

	//chats
	void clientChatsAdd(client* cl, void* chat);
	void* clientChatsGet(client* cl, int id);
	void clientChatsRemove(client* cl, void* chat);

	//processor for client message queue
	void clientMessagesProceed(client *c, void* (*me)(void* d, void * _c), void * arg);

	int clientSetInfo(client *c, user_info *u);

	void clientServerClear(client* c);
}
#define clientCritical(_$_c, action)\
	if(_$_c)\
		t_mutexCritical(_$_c->mutex, action)

#define clientCriticalAuto(_$_c, action) ({\
		typeof(action) _$_o=0;\
		if (_$_c){\
			t_mutexLock(_$_c->mutex);\
				_$_o=(action);\
			t_mutexUnlock(_$_c->mutex);\
		}\
		_$_o;\
	})

#endif
