#include <cstdio>
#include <cstdlib>
#include <math.h>

#include "point.h"
#include "segment.h"
#include "m.h"

namespace share {
	
	segment::segment(){
		
	}

	segment::segment(point _a, point _b):directed(0){
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

	float segment::length(float l){//set length
		auto d=length();
		b.x=a.x+(b.x-a.x)/d*l;
		b.y=a.y+(b.y-a.y)/d*l;
		return length();
	}

	float segment::mul(float l){
		b.x=a.x+(b.x-a.x)*l;
		b.y=a.y+(b.y-a.y)*l;
		return length();
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
	
	bool segment::has_inside(point &t){
		auto a_ = b.y - a.y;
		auto b_ = a.x - b.x;
		auto c_ = - a_ * a.x - b_ * a.y;
		if (abs(a_ * t.x + b_ * t.y + c_) > 0.1) return 0;
		
		return to_quad().contains(t);
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
	
	#define point_t typeof(point::x)

	static inline point crossPoint(point a, point b, point c, point d){
		static auto abc=[](point_t x0, point_t y0, point_t x1, point_t y1, point_t &a, point_t &b, point_t &c ){
			a = y1 - y0;
			b = x0 - x1;
			c = -((x1 - x0) * y0 - (y1 - y0) * x0);      
		};
		static auto det=[]( point_t a1, point_t a2, point_t b1, point_t b2 )->point_t{
			return a1 * b2 - a2 * b1;
		};
		point_t a1,b1,c1,a2,b2,c2;
		abc(a.x,a.y,b.x,b.y, a1, b1, c1 );
		abc(c.x,c.y,d.x,d.y, a2, b2, c2 );

		point_t d0  = det( a1, b1, a2, b2 );
		point_t d1 = det( c1, b1, c2, b2 );
		point_t d2 = det( a1, c1, a2, c2 );

		return d0==0?point(0,0):point(d1 / d0, d2 / d0);
	}
	#undef point_t
	
	typeof(segment::a) segment::cross_point(segment s){
		return crossPoint(a,b,s.a,s.b);
	}
	
	typeof(segment::a) segment::mirror_by(segment s, char &ha){
		auto cp=cross_point(s);
		auto v_=segment(cp, b).to_vector();
		auto v$=segment(cp, a).to_vector();
		auto v1=segment(cp, s.a).to_vector();
		auto v2=segment(cp, s.b).to_vector();
		auto a_=v_.to_angle()?:((v$*-1).to_angle()); //correct if point on segment
		auto a1=(v1.to_angle()?:(v2*-1).to_angle())-a_;
		auto a2=(v2.to_angle()?:(v1*-1).to_angle())-a_;
		ha=((abs(a1)<abs(a2))? a1 : a2);
	
		return cp+v_.rotate(ha).rotate(ha);
	}
	
	segment segment::to_quad(){
		auto x1=min_of(a.x,b.x);
		auto x2=max_of(a.x,b.x);
		auto y1=min_of(a.y,b.y);
		auto y2=max_of(a.y,b.y);
		
		return segment(point(x1,y1),point(x2-x1,y2-y1));
	}
	
	typeof(segment::a) segment::rand_point_in(){
//		printf("rand point in (%g, %g) - (%g, %g)\n", a.x,a.y,this->b.x,this->b.y);
		typeof(segment::a) out(a.x+((rand()%((int)(b.x*10000)+1))/10000.0), a.y+((rand()%((int)(b.y*10000)+1))/10000.0));
//		printf("rand point in (%g, %g) - (%g, %g)\n", a.x,a.y,this->b.x,this->b.y);
		//TODO: why it different on cygwin
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
