#ifndef MESSAGEPROCESSOR_HEADER
#define MESSAGEPROCESSOR_HEADER

namespace master{

	void* messageprocessorClient(int key);

	void* messageprocessorServer(int key);

	int messageprocessorClientAdd(int, void* f);
	int messageprocessorServerAdd(int, void* f);
}

#endif