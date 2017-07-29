#include <glob.h>
#include <cstdio>

#include "folder.h"

#ifndef GLOB_TILDE
	#define GLOB_TILDE 0
#endif

namespace share {
	void folder::forEachFile(char *path, void (*f)(char*)){
		using namespace std;
		glob_t glob_result;
		glob(path, GLOB_TILDE, 0, &glob_result);
		for(unsigned int i=0;i<glob_result.gl_pathc;++i){
			f(glob_result.gl_pathv[i]);
		}
		globfree(&glob_result);
	}
}

/*
int main(){
	share::folder::forEachFile((char*)"../*.h", [](char *s){
		printf("%s\n", s);
	});
	return 0;
}
*/
