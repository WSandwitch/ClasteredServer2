#ifndef LISTENERS_HEADER
#define LISTENERS_HEADER

#include <vector>

#include "../share/system/mutex.h"
#include "../share/network/listener.h"

using namespace share;

namespace master {
	class listeners{
		public:
			static std::vector<share::listener*> all;
			static share::mutex m;
		
			static listener* add(share::listener* l);
			static void clear();
	};
}

void listenersInit();

void listenersClear();

listener* listenersAdd(share::listener* l);

void listenersForEach(void*(f)(listener *l, void *arg));

#endif
