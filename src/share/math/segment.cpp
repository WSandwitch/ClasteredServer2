#include <cstdio>
#include <cstdlib>
#include <math.h>

#include "point.h"
#include "segment.h"

namespace share {
	
	segment::segment(){
		
	}

	segment::segment(point _a, point _b){
		a=_a;
		b=_b;
	}
	
	segment::segment(typeof(point::x) _ax, typeof(point::y) _ay, typeof(point::x) _bx, typeof(point::y) _by){
		a=point(_ax, _ay);
		b=point(_bx, _by);
	}
	
	float segment::distanse(point &p){
		if (point::scalar(point::toVector(a,p), point::toVector(a,b))<0)
			return a.distanse(p);
		if (point::scalar(point::toVector(b,p), point::toVector(b,a))<0)
			return b.distanse(p);
		return fabs(signed_area2(p)/length());
	}

	float segment::signed_area2(point &p){ //the same as vector
		return (b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x);
	}

	float segment::length(){
		return a.distanse(b);
	}

	float segment::length(float l){
		auto d=length();
		b.x+=(b.x-a.x)/d*l;
		b.y+=(b.y-a.y)/d*l;
		return a.distanse(b);
	}

	float segment::mul(float l){
		b.x=(b.x-a.x)*l;
		b.y=(b.y-a.y)*l;
		return a.distanse(b);
	}

	char segment::cross(segment *s){
		typeof(point::x) v1=this->vector(s->a);
		typeof(point::x) v2=this->vector(s->b);
//		printf("%g %g \n",v1,v2);
		if ((v1>=0 && v2<=0) || (v1<=0 && v2>=0)){
			v1=s->vector(this->a);
			v2=s->vector(this->b);
//			printf("%g %g \n",v1,v2);
			if (v1>=0 && v2<=0)
				return 1;
			if (v1<=0 && v2>=0)
				return -1;
		}
		return 0;
	}
	
	typeof(point::x) segment::vector(point &p){
//		printf("%g %g || %g %g | %g %g\n",p.x,p.y,this->a.x,this->a.y,this->b.x,this->b.y);
//		printf("%g %g | %g %g\n",(p.x-this->a.x),(p.y-this->a.y),(this->b.x-this->a.x),(this->b.y-this->a.y));
		return (this->b.x-this->a.x)*(p.y-this->a.y)-(this->b.y-this->a.y)*(p.x-this->a.x);
	}
	
	typeof(segment::a) segment::to_vector(){
		typeof(segment::a) out(b.x+-a.x, b.y-a.y);
		return out;
	}
	
	typeof(segment::a) segment::rand_point_in(){
		typeof(segment::a) out(a.x+((rand()%((int)(b.x*10000)+1))/10000.0), a.y+((rand()%((int)(b.y*10000)+1))/10000.0));
		return out;
	}
}

namespace std {
	ostream& operator<<(ostream &stream, share::segment &s) {
		cout << "[";
		cout << s.a;
		cout << " ";
		cout << s.b;
		cout << "]";
		return stream;
	}
}


/*
using namespace clasteredServerSlave;
int main(){
	point p(-5,0.1);
	point p1(5,10);
	point p2(0,5);
	point p3(0,-5);
	segment s1(p,p1);
	segment s2(p2,p3);
	printf("dist %g\n", s1.vector(p3));
	printf("dist %g\n", s2.vector(p2));
	printf("cross %d\n", s1.cross(&s2));
}
*/
