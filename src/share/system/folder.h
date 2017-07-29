#ifndef CLASTERED_SERVER_FOLDER_HEADER
#define CLASTERED_SERVER_FOLDER_HEADER


namespace share {
	class folder{
		public:
			static void forEachFile(char* path, void (*f)(char*));
	};
}

#endif
