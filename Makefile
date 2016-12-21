OBJDIR ?= /tmp/CCS2_build
ARCH ?= $(uname -m)
GCC ?= gcc
CFLAGS= -Wall -fsigned-char -fgnu89-inline
CPPFLAGS= -Wall -fsigned-char -std=gnu++0x
LDFLAGS= -pthread -lpthread -lm -lstdc++
HEADERS= -Isrc/share/yaml-cpp/include
SRC=src

SHARE_SOURCES:=$(wildcard $(SRC)/share/*.cpp) $(wildcard $(SRC)/share/*/*.cpp) $(wildcard $(SRC)/share/*/*/*.cpp) $(wildcard $(SRC)/share/*/*/*/*.cpp) $(wildcard $(SRC)/share/*/*/*/*/*.cpp)
SHARE_OBJECTS:=$(addprefix $(OBJDIR)/, $(SHARE_SOURCES:.cpp=.o))

PUBLIC:=master
PUBLIC_SOURCES=$(wildcard $(SRC)/$(PUBLIC)/*.cpp) $(wildcard $(SRC)/$(PUBLIC)/*/*.cpp) $(wildcard $(SRC)/$(PUBLIC)/*/*/*.cpp)
PUBLIC_OBJECTS=$(addprefix $(OBJDIR)/, $(PUBLIC_SOURCES:.cpp=.o))

TEST:=test
TEST_SOURCES=$(wildcard $(SRC)/$(TEST)/*.c) $(wildcard $(SRC)/$(TEST)/*/*.c) $(wildcard $(SRC)/$(TEST)/*/*/*.c)
TEST_OBJECTS=$(addprefix $(OBJDIR)/, $(TEST_SOURCES:.c=.o))

SLAVE:=slave
SLAVE_SOURCES=$(wildcard $(SRC)/$(SLAVE)/*.cpp) $(wildcard $(SRC)/$(SLAVE)/*/*.cpp) $(wildcard $(SRC)/$(SLAVE)/*/*/*.cpp)
SLAVE_OBJECTS=$(addprefix $(OBJDIR)/, $(SLAVE_SOURCES:.cpp=.o))

STORAGE?=TEXT

DEFINES:= -DSTORAGE_$(STORAGE)

ifneq ($(DEBUG),0)
    CFLAGS +=-g -ggdb3 -rdynamic
    CPPFLAGS +=-g -ggdb3 -rdynamic
	DEFINES += -DDEBUG
endif

ifeq ($(PARALLEL),1)
	CFLAGS += -fopenmp
    CPPFLAGS += -fopenmp
	LDFLAGS += -fopenmp
    DEFINES += -D_GLIBCXX_PARALLEL
endif

ifeq ($(GPROF),1)
	CFLAGS += -pg
    CPPFLAGS += -pg
	LDFLAGS += -pg
endif

ifeq ($(OPTIMISATION),1)
    CFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -flto -funroll-loops
    CPPFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -flto -funroll-loops
    LDFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -flto -funroll-loops
	ifeq ($(filter $(ARCH),ppc ppc64),)
		CFLAGS += -march=native
		CPPFLAGS += -march=native
		LDFLAGS += -march=native
	endif
endif

all: $(SHARE_SOURCES) $(PUBLIC_SOURCES) $(SLAVE_SOURCES) $(SLAVE) $(PUBLIC) 
	
$(PUBLIC): $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(SLAVE_OBJECTS)
	$(GCC) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(DEFINES) $(SLAVE_OBJECTS) $(LDFLAGS) -o $@

$(TEST): $(SHARE_OBJECTS) $(TEST_OBJECTS) 
	$(GCC) $(SHARE_OBJECTS) $(TEST_OBJECTS) $(DEFINES) $(LDFLAGS) -o $@

$(SLAVE): $(SHARE_OBJECTS) $(SLAVE_OBJECTS) $(OBJDIR)/src/slave_main.o
	$(GCC) $(SHARE_OBJECTS) $(SLAVE_OBJECTS) $(DEFINES) $(OBJDIR)/src/slave_main.o $(LDFLAGS) -o $@

$(OBJDIR)/%.o: %.c 
	@mkdir -p $(@D)
	$(GCC) -c $(CFLAGS) $(DEFINES) $(HEADERS) $< -o $@

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(GCC) -c $(CPPFLAGS) $(DEFINES) $(HEADERS) $< -o $@
	
generator: 
	$(GCC) $(SRC)/other/password_generator.c $(SRC)/share/md5.c $(SRC)/share/base64.c -o generator

fast: $(PUBLIC)_fast
	
$(PUBLIC)_fast:
	$(GCC) $(CPPFLAGS) $(SHARE_SOURCES) $(PUBLIC_SOURCES) $(LDFLAGS) -o $(PUBLIC)

clean:
	rm -rf $(SLAVE_OBJECTS) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(TEST_OBJECTS) $(PUBLIC) $(TEST) $(PUBLIC).exe $(SLAVE) $(SLAVE).exe $(TEST).exe generator.exe generator src/slave_main.o