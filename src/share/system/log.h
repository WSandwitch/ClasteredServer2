#ifndef LOG_HEADER
#define LOG_HEADER

#include <cstdio>

struct log_config;
struct log_config{
	log_config();
	char file[200];
	short debug;
	
	static log_config config;
};

void printLog(const char* format, ...);

#define printf printLog
#define printRaw printf

#define perror(str) printLog("%s at %s <%s:%d>\n",str,__FUNCTION__,__FILE__,__LINE__)

#endif