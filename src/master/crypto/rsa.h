#pragma once

#include <openssl/rand.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/err.h>

#include <string>

namespace master{
	
	class rsa{
		public:
		
			rsa(int kBits = 1024, int kExp = 7);
			~rsa();
			std::string private_key();
			std::string public_key();
			int size();
			int encrypt(int size, const void* input, void* output);
			int decrypt(int size, const void* input, void* output);
		protected:
			RSA *_rsa;

			static int padding;
	};
	
}