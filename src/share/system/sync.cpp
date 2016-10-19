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
	
	void sync::syncTPS(int TPS){
		int diff=timePassed();
		if (TPS){
			if((diff=(1000000/TPS)-diff)>0){
				usleep(diff);
			}
		}
	}
}
