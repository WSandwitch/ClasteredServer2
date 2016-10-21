#ifndef BASE64_HEADER
#define BASE64_HEADER

namespace share {
	class base64{
		public:
			static int decode(unsigned char in[], unsigned char out[], int len);
			static int encode(unsigned char in[], unsigned char out[], int len, int newline_flag);
	};
}
#endif