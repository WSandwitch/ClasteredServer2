#ifndef LISTENERS_HEADER
#define LISTENERS_HEADER

#include <vector>
#include "../share/system/mutex.h"
#include "../share/network/listener.h"

namespace master {
	class listeners{
		public:
			static std::vector<listener*> all;
			static mutex m;
		
			static add(listener* l);
	};
}

void listenersInit();

void listenersClear();

listener* listenersAdd(listener* l);

void listenersForEach(void*(f)(listener *l, void *arg));

#endif
