#ifndef MESSAGEPROCESSOR_HEADER
#define MESSAGEPROCESSOR_HEADER

#include "../share/containers/bintree.h"


void* messageprocessorClient(int key);

void* messageprocessorServer(int key);

bintree_key messageprocessorClientAdd(bintree_key key, void* f);
bintree_key messageprocessorServerAdd(bintree_key key, void* f);

void messageprocessorClear();

#endif