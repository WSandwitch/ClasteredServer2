#include <stdarg.h>
#include <time.h>
#include <unistd.h> 
#include <string.h> 

#include "log.h"
#include "time.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	good log printing 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

log_config::log_config(): debug(1){
	memset(file, 0, sizeof(file));
	//Add fopen...
}
log_config log_config::config;

//can be used as printf
void printLog(const char* format, ...) {
	char str[800];
	char tstr[20]="";
	log_config *config=&log_config::config;
	timestamp_t t=time(0);
	strftime(tstr, sizeof(tstr), "%F %T", localtime((time_t*)&t));
	va_list argptr;
	va_start(argptr, format);
		vsprintf(str, format, argptr);
	va_end(argptr);	
	
	if (config->debug){
		fprintf(stdout, "%s: %s", tstr, str);
		fflush(stdout);
	}
	if (config->file[0]!=0){
		FILE *f=fopen(config->file, "a");
		if (f){
			fprintf(f, "%s: %s", tstr, str);
			fclose(f);
		}
	}
}