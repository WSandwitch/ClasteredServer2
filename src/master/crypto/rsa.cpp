#include <cstdlib>
#include <cstdio>

#include "../../share/system/time.h"
#include "rsa.h"

namespace master{

	int rsa::padding=RSA_PKCS1_OAEP_PADDING;
	
	rsa::rsa(int kBits, int kExp){
		struct {
			int $1;
			timestamp_t $2;
		} tokenbase={rand(), time(0)};
		RAND_seed(&tokenbase, sizeof(tokenbase));
		_rsa = RSA_generate_key(kBits, kExp, 0, 0);
	}
	
	rsa::~rsa(){
		RSA_free(_rsa);
	}
	
	std::string rsa::public_key(){
		BIO *bio = BIO_new(BIO_s_mem());
		PEM_write_bio_RSAPublicKey(bio, _rsa);

		int keylen = BIO_pending(bio);
		char *pem_key = (char*)calloc(keylen+1, 1); /* Null-terminate */
		BIO_read(bio, pem_key, keylen);
		std::string s(pem_key);
		
		BIO_free_all(bio);
		free(pem_key);
		
		return s;
	}
	
	std::string rsa::private_key(){
		BIO *bio = BIO_new(BIO_s_mem());
		PEM_write_bio_RSAPrivateKey(bio, _rsa, NULL, NULL, 0, NULL, NULL);

		int keylen = BIO_pending(bio);
		char *pem_key = (char*)calloc(keylen+1, 1); /* Null-terminate */
		BIO_read(bio, pem_key, keylen);
		std::string s(pem_key);
		
		BIO_free_all(bio);
		free(pem_key);
		
		return s;
	}
	
	int rsa::size(){
		return RSA_size(_rsa);
	}
	
	int rsa::encrypt(int size, const void* input, void* output){
		return RSA_public_encrypt(
			size, 
			(const unsigned char*)input, 
			(unsigned char*)output, 
			_rsa, 
			padding
		);
	}
	
	int rsa::decrypt(int size, const void* input, void* output){
		return RSA_private_decrypt(			
			size, 
			(const unsigned char*)input, 
			(unsigned char*)output, 
			_rsa, 
			padding
		);
	}
	
}

/*
using namespace master;
int main(){
	rsa r;
	printf("%s\n", r.public_key().data());
	std::string s("123ewdsadaw");
	void *data=malloc(r.size()+1);
	memset(data, 0 , r.size()+1);
	int size=r.encrypt(s.size(), s.data(), data);
	
	char str[200]={0};
	r.decrypt(size, data, str);
	
	printf("%d, %s - %s\n", r.size(), s.data(), str);
	return 0;
}
*/