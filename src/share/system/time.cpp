#include <time.h>
#include "time.h"

namespace share {
	timestamp_t time(void* a){
		return ::time((time_t*)a);
	}
}
