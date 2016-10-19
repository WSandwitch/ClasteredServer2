#ifndef CLIENT_MESSAGES_HEADER
#define CLIENT_MESSAGES_HEADER

#define MSG_C_SUCCESS 1
#define MSG_C_AUTH_TOKEN 2
#define MSG_C_USER_INFO 3
#define MSG_C_ERROR 4
#define MSG_C_CHAT_JOINED 5
#define MSG_C_CHAT_QUITED 6
#define MSG_C_CHAT_MESSAGE 7
#define MSG_C_QUIT 8

void clientMessageProcessorInit();

#endif
