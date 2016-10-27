#ifndef CLASTERED_SERVER_SLAVE_SEGMENT_HEADER
#define CLASTERED_SERVER_SLAVE_SEGMENT_HEADER

#include <iostream>

#include "point.h"

namespace share {
	class segment{
		public:
			point a,b;
			
			segment();
			segment(point _a, point _b);
			segment(typeof(point::x) _ax, typeof(point::y) _ay, typeof(point::x) _bx, typeof(point::y) _by);
			float distanse(point &p);
			float length();
			bool cross(segment *b);
			typeof(point::x) vector(point &p);
		
			friend std::ostream& operator<<(std::ostream &stream, const segment &s);
	};
	
}

#endif
