#pragma once

template<class T>
char get_type(T a){return 0;}

inline char get_type(char &a){return 1;}
inline char get_type(short &a){return 2;}
inline char get_type(int &a){return 3;}
inline char get_type(float &a){return 4;}
inline char get_type(double &a){return 5;}
