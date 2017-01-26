#pragma once

#include <openssl/rand.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/bn.h>

#include <string>

namespace master{
	
	class rsa{
		public:
		
			rsa(int kBits = 2048, int kExp = 0);
			~rsa();
			std::string private_key();
			std::string public_key();
			int size();
			std::string get_e();
			std::string get_n();
			int encrypt(int size, const void* input, void* output);
			int decrypt(int size, const void* input, void* output);
		protected:
			RSA *_rsa;

			static int padding;
	};
	
}