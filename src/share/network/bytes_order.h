#ifndef BYTES_ORDER_HEADER
#define BYTES_ORDER_HEADER

static inline char changeEndianes(char a){
	return a;
}

static inline short changeEndianes(short a){
	return (a << 8) | ((a >> 8) & 0xFF);
}

static inline int changeEndianes(int a){
	a = ((a << 8) & 0xFF00FF00) | ((a >> 8) & 0xFF00FF );
	return (a << 16) | ((a >> 16) & 0xFFFF);
}

static inline long long changeEndianes(long long a){
	a = ((a << 8) & 0xFF00FF00FF00FF00ULL ) | ((a >> 8) & 0x00FF00FF00FF00FFULL );
	a = ((a << 16) & 0xFFFF0000FFFF0000ULL ) | ((a >> 16) & 0x0000FFFF0000FFFFULL );
	a = (a << 32) | ((a >> 32) & 0xFFFFFFFFULL);
	return a;
}


static inline float changeEndianes(float a){
	register union{typeof(a) orig;int val;} u;
	u.orig=a;
	u.val = ((u.val << 8) & 0xFF00FF00) | ((u.val >> 8) & 0xFF00FF );
	u.val = (u.val << 16) | ((u.val >> 16) & 0xFFFF);
	return u.orig;
}

static inline double changeEndianes(double a){
	register union{typeof(a) orig;long long val;}u;
	u.orig=a;
	u.val = ((u.val << 8) & 0xFF00FF00FF00FF00ULL ) | ((u.val >> 8) & 0x00FF00FF00FF00FFULL );
	u.val = ((u.val << 16) & 0xFFFF0000FFFF0000ULL ) | ((u.val >> 16) & 0x0000FFFF0000FFFFULL );
	u.val = (u.val << 32) | ((u.val >> 32) & 0xFFFFFFFFULL);
	return u.orig;
}

#define changeEndianesM(a) ({ register typeof(a) out;\
		if (sizeof(a) == 2){\
			register union{typeof(a) orig;short val;}u;u.orig=a;\
			u.val=(u.val << 8) | ((u.val >> 8) & 0xFF);\
			out=u.orig;\
		}else if (sizeof(a) == 4){\
			register union{typeof(a) orig;int val;}u;u.orig=a;\
			u.val = ((u.val << 8) & 0xFF00FF00) | ((u.val >> 8) & 0xFF00FF );\
			u.val = (u.val << 16) | ((u.val >> 16) & 0xFFFF);\
			out=u.orig;\
		} else if (sizeof(a) == 8){\
			register union{typeof(a) orig;long long val;}u;u.orig=a;\
			u.val = ((u.val << 8) & 0xFF00FF00FF00FF00ULL ) | ((u.val >> 8) & 0x00FF00FF00FF00FFULL );\
			u.val = ((u.val << 16) & 0xFFFF0000FFFF0000ULL ) | ((u.val >> 16) & 0x0000FFFF0000FFFFULL );\
			u.val = (u.val << 32) | ((u.val >> 32) & 0xFFFFFFFFULL);\
			out=u.orig;\
		}else out=a;\
	out;})
//TODO: change to faster version, and create test


#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__

#define byteSwap(a) changeEndianes(a)

#else

#define byteSwap(a) (a)

#endif


int wrongByteOrder();

#endif