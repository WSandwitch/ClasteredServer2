#include <cstdlib>
#include <cstdio>

#include "../../share/system/time.h"
#include "rsa.h"

namespace master{

	int rsa::padding=RSA_PKCS1_PADDING;//RSA_NO_PADDING;//RSA_PKCS1_OAEP_PADDING;
	
	rsa::rsa(int kBits, int kExp){
		struct {
			int $1;
			timestamp_t $2;
		} tokenbase={rand(), share::time(0)};
		RAND_seed(&tokenbase, sizeof(tokenbase));
		
		_rsa = RSA_generate_key(kBits, kExp?:7, 0, 0); 
	}
	
	rsa::~rsa(){
		RSA_free(_rsa);
	}
	
	std::string rsa::public_key(){
		BIO *bio = BIO_new(BIO_s_mem());
		PEM_write_bio_RSA_PUBKEY(bio, _rsa);
		//PEM_write_bio_RSAPublicKey(bio, _rsa);

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
	
	std::string rsa::get_e(){
		char *str = BN_bn2hex(_rsa->e);
		std::string s(str);
		OPENSSL_free(str);
		return s;
	}
	
	std::string rsa::get_n(){
		char *str = BN_bn2hex(_rsa->n);
		std::string s(str);
		OPENSSL_free(str);
		return s;
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
		int o=RSA_private_decrypt(			
			size, 
			(const unsigned char*)input, 
			(unsigned char*)output, 
			_rsa, 
			padding
		);
		if(o<0){
			char* err=(char*)malloc(130);
			ERR_load_crypto_strings();
			ERR_error_string(ERR_get_error(), err);
			printf("%s\n", err);
			free(err);
		}
		return o;
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