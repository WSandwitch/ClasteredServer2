#ifndef CLIENT_HEADER
#define CLIENT_HEADER

#include <list>
#include <unordered_map>
#include <unordered_set>
#include <string>
#include <array>
#include <sys/time.h>

#include "storage.h"
#include "../share/npc.h"
#include "../share/system/time.h"
#include "../share/system/mutex.h"
#include "../share/network/socket.h"
#include "../share/network/packet.h"

#define CLIENT_CONN_SOCKET 1
#define MSG_CLIENT 1


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
			
			std::array<int, 2> view_area;
			std::array<int, 2> view_position;

			short conn_type;
			short broken;
			int server_id;
			share::socket* sock;
			int npc_id;
			share::mutex mutex;
			std::list<client_message*> messages;
			std::unordered_set<int> npcs; 
			timestamp_t timestamp;
			char token[30];
			
			client(share::socket* sock);
			~client();
			int proceed(share::packet* p);
			void messages_add(client_message *m);
			
			void messages_proceed();
			int set_info(user_info *u);
			void server_clear();
		
			static share::mutex m;
			static std::unordered_map<int, client*> all;
		
			static int add(client* c);
			static client* get(int id);
			static void remove(client* c);
			static void check();
			static void broadcast(client_message *m);
	};

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
