#ifndef CLASTERED_SERVER_SLAVE_MESSAGES_PROCESSOR_HEADER
#define CLASTERED_SERVER_SLAVE_MESSAGES_PROCESSOR_HEADER

#include <map>

#include "../share/network/packet.h"

extern "C"{

}

namespace slave {
	typedef void*(*processor)(share::packet*);
	class processors;
	
	class processors{
			processors();
		public:
			static processors init;
		
			static std::map<char, processor> messages;
	};
}


#endif
