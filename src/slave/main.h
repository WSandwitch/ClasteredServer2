#pragma once

//start slave as thread of master
int start_slave(int port);

int start_slave_fork(int port);

int slave_main(int argc, char* argv[]);

