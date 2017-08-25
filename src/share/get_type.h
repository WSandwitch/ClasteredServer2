#pragma once

template<class T>
	static inline char get_type(T){return 0;}

static inline char get_type(char){return 1;}
static inline char get_type(short){return 2;}
static inline char get_type(int){return 3;}
static inline char get_type(float){return 4;}
static inline char get_type(double){return 5;}
