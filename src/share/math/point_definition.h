
#include <math.h>

#include "m.h" //for sqr
#include "point.h"

namespace share {

	template<class T>
		point_<T>::point_(): x(0), y(0){
		}

	template<class T>		
		point_<T>::point_(T x, T y): x(x), y(y){
		}

	template<class T>		
		void point_<T>::normalize(){
			float l=sqrtf(sqr(x)+sqr(y));
			if (l>0){
				x=x/l;
				y=y/l;
			}
		}

	template<class T>		
		char point_<T>::to_angle(){
			return to_pdegrees(atan2f(y,x));  //pseudo radians [-120, 120]
		}

	template<class T>
		template<class T1>
			void point_<T>::by_angle(char angle, T1 l){
				float rad=from_pdegrees(angle);
				x=roundf(l*cosf(rad));//TODO:check
				y=roundf(l*sinf(rad));
			}
		
	template<>
		template<class T1>
			void point_<float>::by_angle(char angle, T1 l){
				float rad=from_pdegrees(angle);
				x=l*cosf(rad);//TODO:check
				y=l*sinf(rad);
			}
		
	template<class T>
		template<class T1, class T2>		
			float point_<T>::length(T1 x, T2 y){
				return sqrtf(sqr(x)+sqr(y));
			}
		
	template<class T>
		float point_<T>::length(point_<T> &p){
			return length(p.x,p.y);
		}
		
	template<class T>
	template<class T1>		
		float point_<T>::distanse(point_<T1> &b){
			return sqrtf(sqr(b.x-x)+sqr(b.y-y));
		}

	template<class T>
	template<class T1>
		T point_<T>::distanse2(point_<T1> &b){
			return sqr(b.x-x)+sqr(b.y-y);
		}

	template<class T>
	template<class T1>
		point_<T> point_<T>::operator+(point_<T1> &&b){
			return point_<T>(x+b.x,y+b.y);
		}

	template<class T>
	template<class T1>
		point_<T> point_<T>::operator-(point_<T1> &&b){
			return point_<T>(x-b.x,y-b.y);
		}

	template<class T>
	template<class T1>		
		point_<T> point_<T>::from_angle(char angle, T1 l){
			point_<T> p;
			p.by_angle(angle,l);
			return p;
		}

	template<class T>
	template<class T1, class T2>
		T point_<T>::scalar(point_<T1> &&a, point_<T2> &&b){
			return a.x*b.x+a.y*b.y;
		}

	template<class T>
	template<class T1, class T2>
		point_<T> point_<T>::toVector(point_<T1> &a, point_<T2> &b){
			point_<T> o(b.x-a.x, b.y-a.y);
			return o;
		}	
/* 
//if you want to compile this file as .cpp and use only short, int, float
#define explicit_instantiation_3(T,T1,T2)\
	template T point_<T>::scalar(point_<T1> &&a, point_<T2> &&b);\
	template point_<T> point_<T>::toVector(point_<T1> &a, point_<T2> &b);

#define explicit_instantiation_2(T,T1)\
	template T point_<T>::distanse2(point_<T1>&b);\
	template float point_<T>::distanse(point_<T1> &b);
	
	template class point_<short>;
	template class point_<int>;
	template class point_<float>;
	
	explicit_instantiation_2(short, short)
	explicit_instantiation_2(short, int)
	explicit_instantiation_2(short, float)
	explicit_instantiation_2(int, short)
	explicit_instantiation_2(int, int)
	explicit_instantiation_2(int, float)
	explicit_instantiation_2(float, short)
	explicit_instantiation_2(float, int)
	explicit_instantiation_2(float, float)
	
	explicit_instantiation_3(short, short, short)
	explicit_instantiation_3(short, short, int)
	explicit_instantiation_3(short, short, float)
	explicit_instantiation_3(short, int, short)
	explicit_instantiation_3(short, int, int)
	explicit_instantiation_3(short, int, float)
	explicit_instantiation_3(short, float, short)
	explicit_instantiation_3(short, float, int)
	explicit_instantiation_3(short, float, float)
	explicit_instantiation_3(int, short, short)
	explicit_instantiation_3(int, short, int)
	explicit_instantiation_3(int, short, float)
	explicit_instantiation_3(int, int, short)
	explicit_instantiation_3(int, int, int)
	explicit_instantiation_3(int, int, float)
	explicit_instantiation_3(int, float, short)
	explicit_instantiation_3(int, float, int)
	explicit_instantiation_3(int, float, float)
	explicit_instantiation_3(float, short, short)
	explicit_instantiation_3(float, short, int)
	explicit_instantiation_3(float, short, float)
	explicit_instantiation_3(float, int, short)
	explicit_instantiation_3(float, int, int)
	explicit_instantiation_3(float, int, float)
	explicit_instantiation_3(float, float, short)
	explicit_instantiation_3(float, float, int)
	explicit_instantiation_3(float, float, float)
*/
}
