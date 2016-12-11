#include <cstdio>
#include <cstdlib>
#include "sync.h"

namespace share {
	sync::sync(){
		timePassed();
	}
	
	int sync::timePassed(){
		struct timeval end;
		gettimeofday(&end, 0);
		int out=((end.tv_sec - t.tv_sec)*1000000+
				end.tv_usec - t.tv_usec);
		memcpy(&t,&end,sizeof(end));
		return out;
	}
	
	void sync::syncTPS(int TPS, bool l){
		int diff=timePassed();
#ifdef DEBUG
		if (l)
			printf("spt\t%d\tsleep\t%d\tfull\t%d\n", diff, (1000000/TPS)-diff, (1000000/TPS));
#endif
		if (TPS){
			if((diff=(1000000/TPS)-diff)>0){
				usleep(diff);
			}
		}
	}
}
