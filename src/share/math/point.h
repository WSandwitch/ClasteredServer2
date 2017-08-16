#ifndef CLASTERED_SERVER_SLAVE_POINT_HEADER
#define CLASTERED_SERVER_SLAVE_POINT_HEADER

#include <iostream>

namespace share {
	
	template <class T>
		class point_{
			public:
				T x,y;
				
				point_();
				point_(T _x, T _y);
				void normalize(bool _const=1);
				char to_angle();
				template <class T1>
					void by_angle(char angle, T1 l=1);
				template<class T1>
					float distanse(point_<T1> &b);
				template<class T1>
					T distanse2(point_<T1> &b);
				template<class T1>
					point_ operator+(point_<T1> &&b);
				template<class T1>
					point_ operator-(point_<T1> &&b);
			
				template <class T1>
					static point_ from_angle(char angle, T1 l);//l is length of vector
				template<class T1, class T2>
					static T scalar(point_<T1> &&a, point_<T2> &&b);
				template<class T1, class T2>
					static point_<T> toVector(point_<T1> &a, point_<T2> &b);
				template<class T1, class T2>		
					static float length(T1 x, T2 y);
				static float length(point_ &p);
				
				template <class T1>
					friend std::ostream& operator<<(std::ostream &stream, const point_<T1> &p);
		};
	
	
	typedef point_<float> point;
	
	typedef point_<short> points;
	typedef point_<int> pointi;
	typedef point_<float> pointf;
	
}

#include "point_definition.h"

namespace std {
	template <class T>
	ostream& operator<<(ostream &stream, share::point_<T> &p) {
		cout << "(";
		cout << p.x;
		cout << " ";
		cout << p.y;
		cout << ")";
		return stream;
	}
}
#endif