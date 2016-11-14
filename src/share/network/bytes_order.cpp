#include <cstdio>

#include "bytes_order.h"
//#include "../system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ byte order changer 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

int wrongByteOrder(){
	int o=0;
	char c4[4]={-92, 112, 69, 65};
	float *f=(float *)(void*)c4, f0=12.34;
	int *i=(int *)(void*)c4, i0=1095069860;
	if (byteSwap(*i)!=i0){
		perror("wrongByteOrder int");
		o++;
	}
	if (byteSwap(*f)!=f0){
		perror("wrongByteOrder float");
		o++;
	}
	char c8[8]={-82, 71, -31, 122, 20, -82, 40, 64};
	long long *l=(typeof(l))(void*)c8, l0=4623136420479977390;
	double *d=(typeof(d))(void*)c8, d0=12.34;
	if (byteSwap(*l)!=l0){
		perror("wrongByteOrder long long");
		o++;
	}
	if (byteSwap(*d)!=d0){
		perror("wrongByteOrder double");
		o++;
	}
	return o;
}

/*
int main(){
	wrongByteOrder();
	srand(time(0));
	int i=rand();
	int j=rand();
	int k=rand();
	long long l=rand();
	double d=rand();
	for(i=0;i<10000;i++)
		for(j=0;j<100000;j++){
//			d=i+byteSwap(d)*j;
			k=j+byteSwap(k)*j;
//			l=l+byteSwap(l)*j;
		}
	printf("%d %g %lld\n",k,d,l);
	return 0;
}

*/
