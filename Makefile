BUILD_TMP ?= /tmp
OBJDIR ?= $(BUILD_TMP)/CS2_build
ARCH ?= $(shell uname -m)
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

DEPS := $(SHARE_OBJECTS:.o=.d) $(PUBLIC_OBJECTS:.o=.d) $(SLAVE_OBJECTS:.o=.d)

STORAGE?=TEXT

DEFINES:= -DSTORAGE_$(STORAGE)

ifneq ($(DEBUG),0)
    CFLAGS +=-g -ggdb3 -rdynamic -fno-omit-frame-pointer
    CPPFLAGS +=-g -ggdb3 -rdynamic -fno-omit-frame-pointer
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
    CFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -funroll-loops -fmodulo-sched -fmodulo-sched-allow-regmoves #-fprofile-use
    CPPFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -funroll-loops -fmodulo-sched -fmodulo-sched-allow-regmoves #-fprofile-use
    LDFLAGS +=-O3 -ffast-math -fgcse-sm -fgcse-las -fgcse-after-reload -funroll-loops -fmodulo-sched -fmodulo-sched-allow-regmoves #-fprofile-use
	ifneq ($(NO_LTO),1)
		CFLAGS +=-flto
		CPPFLAGS +=-flto
		LDFLAGS +=-flto
	endif
	ifeq ($(filter $(ARCH),ppc ppc64),)
		CFLAGS += -march=native
		CPPFLAGS += -march=native
		LDFLAGS += -march=native
	endif
	ifneq ($(filter $(ARCH), armv7l),)
		CFLAGS += -mfloat-abi=hard -mfpu=neon -mthumb-interwork
		CPPFLAGS += -mfloat-abi=hard -mfpu=neon -mthumb-interwork
		LDFLAGS += -mfloat-abi=hard -mfpu=neon -mthumb-interwork
	endif
endif

all: $(SHARE_SOURCES) $(PUBLIC_SOURCES) $(SLAVE_SOURCES) $(SLAVE) $(PUBLIC) 

arch:
	echo $(ARCH)

$(PUBLIC): $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(SLAVE_OBJECTS)
	$(GCC) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(DEFINES) $(SLAVE_OBJECTS) $(LDFLAGS) -lcrypto -o bin/$@.$(ARCH)

$(TEST): $(SHARE_OBJECTS) $(TEST_OBJECTS) 
	$(GCC) $(SHARE_OBJECTS) $(TEST_OBJECTS) $(DEFINES) $(LDFLAGS) -o bin/$@.$(ARCH)

$(SLAVE): $(SHARE_OBJECTS) $(SLAVE_OBJECTS) $(OBJDIR)/src/slave_main.o
	$(GCC) $(SHARE_OBJECTS) $(SLAVE_OBJECTS) $(DEFINES) $(OBJDIR)/src/slave_main.o $(LDFLAGS) -o bin/$@.$(ARCH)

$(OBJDIR)/%.o: %.c 
	@mkdir -p $(@D)
	$(GCC) -c $(CFLAGS) $(DEFINES) $(HEADERS) $< -o $@

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(GCC) -c $(CPPFLAGS) $(DEFINES) $(HEADERS) -MMD $< -o $@
	
fast: $(PUBLIC)_fast
	
$(PUBLIC)_fast:
	$(GCC) $(CPPFLAGS) $(SHARE_SOURCES) $(PUBLIC_SOURCES) $(LDFLAGS) $(DEFINES) $(HEADERS) -o bin/$(PUBLIC).$(ARCH)

clean:
	rm -rf $(SLAVE_OBJECTS) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(TEST_OBJECTS) $(DEPS) bin/$(PUBLIC)* bin/$(SLAVE)* src/slave_main.o

client:
	lime build neko -debug #-final
	
	
-include $(DEPS)