GCC ?= gcc
CFLAGS= -Wall -fsigned-char -fgnu89-inline 
CPPFLAGS= -Wall -fsigned-char -std=gnu++0x
LDFLAGS= -pthread -lpthread -lm -lstdc++
SRC=src
SHARE_SOURCES:=$(wildcard $(SRC)/share/*.cpp) $(wildcard $(SRC)/share/*/*.cpp) $(wildcard $(SRC)/share/*/*/*.cpp)
SHARE_OBJECTS:=$(SHARE_SOURCES:.cpp=.o)

STORAGE?=TEXT

DEFINES:= -DSTORAGE_$(STORAGE)

PUBLIC:=master
PUBLIC_SOURCES=$(wildcard $(SRC)/$(PUBLIC)/*.cpp) $(wildcard $(SRC)/$(PUBLIC)/*/*.cpp) $(wildcard $(SRC)/$(PUBLIC)/*/*/*.cpp)
PUBLIC_OBJECTS=$(PUBLIC_SOURCES:.cpp=.o)

TEST:=test
TEST_SOURCES=$(wildcard $(SRC)/$(TEST)/*.c) $(wildcard $(SRC)/$(TEST)/*/*.c) $(wildcard $(SRC)/$(TEST)/*/*/*.c)
TEST_OBJECTS=$(TEST_SOURCES:.c=.o)

SLAVE:=slave
SLAVE_SOURCES=$(wildcard $(SRC)/$(SLAVE)/*.cpp) $(wildcard $(SRC)/$(SLAVE)/*/*.cpp) $(wildcard $(SRC)/$(SLAVE)/*/*/*.cpp)
SLAVE_OBJECTS=$(SLAVE_SOURCES:.cpp=.o)

ifeq ($(DEBUG),1)
    CFLAGS +=-g -ggdb -rdynamic
    CPPFLAGS +=-g -ggdb -rdynamic
endif

ifeq ($(OPTIMISATION),1)
    CFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -flto -funroll-loops
    CPPFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -flto -funroll-loops
endif

all: $(SHARE_SOURCES) $(PUBLIC_SOURCES) $(SLAVE_SOURCES) $(PUBLIC) $(SLAVE)
	
$(PUBLIC): $(SHARE_OBJECTS) $(PUBLIC_OBJECTS)
	$(GCC) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(LDFLAGS) -DMASTER -o $@

$(TEST): $(SHARE_OBJECTS) $(TEST_OBJECTS) 
	$(GCC) $(SHARE_OBJECTS) $(TEST_OBJECTS) $(LDFLAGS) -o $@

$(SLAVE): $(SHARE_OBJECTS) $(SLAVE_OBJECTS) 
	$(GCC) $(SHARE_OBJECTS) $(SLAVE_OBJECTS) $(LDFLAGS) -o $@

%.o: %.c
	$(GCC) -c $(CFLAGS) $(DEFINES) $< -o $@

%.o: %.cpp
	$(GCC) -c $(CPPFLAGS) $(DEFINES) $< -o $@
	
generator: 
	$(GCC) $(SRC)/other/password_generator.c $(SRC)/share/md5.c $(SRC)/share/base64.c -o generator

fast: $(PUBLIC)_fast
	
$(PUBLIC)_fast:
	$(GCC) $(CFLAGS) $(SHARE_SOURCES) $(PUBLIC_SOURCES) $(LDFLAGS) -o $(PUBLIC)

clean:
	rm -rf $(SLAVE_OBJECTS) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(TEST_OBJECTS) $(PUBLIC) $(TEST) $(PUBLIC).exe $(SLAVE) $(SLAVE).exe $(TEST).exe generator.exe generator