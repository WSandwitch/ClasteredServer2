#ifndef CLASTERED_SERVER_SLAVE_MESSAGES_PROCESSOR_HEADER
#define CLASTERED_SERVER_SLAVE_MESSAGES_PROCESSOR_HEADER

#include <map>

#include "../../share/network/packet.h"

extern "C"{

}

namespace clasteredServerSlave {
	typedef void*(*processor)(share::packet*);
	struct processors{
		static std::map<char, processor> messages;
		static void init();
	};
}


#endif
