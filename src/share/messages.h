#pragma once

//auth
#define MSG_C_USER_INFO 3

///massages from client
#define MESSAGE_AUTH 1
#define MESSAGE_SET_ACTIONS 2
#define MESSAGE_SET_ATTRS 3
#define MESSAGE_GET_NPC_INFO 4

///master -> slave
#define MESSAGE_PAUSE 1

//slave -> master
#define MESSAGE_SERVER_INFO 1
#define MESSAGE_SERVER_READY 2
#define MESSAGE_NPC_HURT 5
#define MESSAGE_NPC_SUICIDE 6
#define MESSAGE_NPC_MAKE_SHOT 7

///slave, master, client
#define MESSAGE_NPC_UPDATE 3
#define MESSAGE_NPC_REMOVE 4

//master > client
#define MESSAGE_CLIENT_UPDATE 6 //>c

