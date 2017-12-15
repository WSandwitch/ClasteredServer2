BUILD_TMP ?= /tmp
OBJDIR ?= $(BUILD_TMP)/CS2_build
ARCH ?= $(shell uname -m)
GCC ?= gcc
CFLAGS= -Wall -fsigned-char -fgnu89-inline
CPPFLAGS= -Wall -fsigned-char -std=gnu++0x #-Wextra
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

#ppc64
ifneq ($(filter $(ARCH),ppc64),)
	CFLAGS += -m64
	CPPFLAGS += -m64
	LDFLAGS += -m64
endif

ifeq ($(OPTIMISATION),1)
    CFLAGS +=-O3 -fgcse-sm -fgcse-las -fgcse-after-reload -funroll-loops -fmodulo-sched -fmodulo-sched-allow-regmoves #-ftree-vectorizer-verbose=2 #-fprofile-use
    CPPFLAGS +=-O3 -fgcse-sm -fgcse-las -fgcse-after-reload -funroll-loops -fmodulo-sched -fmodulo-sched-allow-regmoves #-ftree-vectorizer-verbose=2 #-fprofile-use
    LDFLAGS +=-O3 -fgcse-sm -fgcse-las -fgcse-after-reload -funroll-loops -fmodulo-sched -fmodulo-sched-allow-regmoves #-ftree-vectorizer-verbose=2 #-fprofile-use
	#not for ppc
	ifeq ($(filter $(ARCH),ppc ppc64),)
		CFLAGS += -march=native -ffast-math #check if slave will work with fast-math
		CPPFLAGS += -march=native -ffast-math 
		LDFLAGS += -march=native -ffast-math  
	endif
	#x86
	ifneq ($(filter $(ARCH),x86_64 i686 i386 i486 i586),)
		CFLAGS += -mpc32
		CPPFLAGS += -mpc32
		LDFLAGS += -mpc32
	endif
	#ppc all
	ifneq ($(filter $(ARCH),ppc ppc64),)
		#add fast-math to ppc slave build
		ifneq ($(filter $(MAKECMDGOALS), slave),)
			CFLAGS += -ffast-math
			CPPFLAGS += -ffast-math
			LDFLAGS += -ffast-math
		endif
		CFLAGS += -mabi=altivec -maltivec -mhard-float -msingle-float -mvrsave -misel -mpaired -mfriz
		CPPFLAGS += -mabi=altivec -maltivec -mhard-float -msingle-float -mvrsave -misel -mpaired -mfriz
		LDFLAGS += -mabi=altivec -maltivec -mhard-float -msingle-float -mvrsave -misel -mpaired -mfriz
		#disable lto
		NO_LTO := 1
	endif
	#arm
	ifneq ($(filter $(ARCH), armv7l aarch64),)
		CFLAGS += -mfloat-abi=hard -mfpu=neon -marm #-mthumb-interwork
		CPPFLAGS += -mfloat-abi=hard -mfpu=neon -marm #-mthumb-interwork
		LDFLAGS += -mfloat-abi=hard -mfpu=neon -marm #-mthumb-interwork
		ifneq ($(filter $(MAKECMDGOALS), master),)
			NO_LTO := 1
		endif
	endif
	#may be dangerous
	ifneq ($(NO_LTO),1)
		CFLAGS +=-flto
		CPPFLAGS +=-flto
		LDFLAGS +=-flto
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
	rm -rf $(SLAVE_OBJECTS) $(SHARE_OBJECTS) $(PUBLIC_OBJECTS) $(TEST_OBJECTS) $(DEPS) src/slave_main.o

cleanall: clean
	rm  bin/$(PUBLIC)* bin/$(SLAVE)*

client:
	lime build neko -debug #-final
#	lime build ios -debug -simulator
#	xcrun simctl install booted /path/to/Your.app
	
gcc5:  # sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
	apt-get update
	apt-get install gcc-5 g++-5 gcc-5-multilib g++-5-multilib build-essential libssl-dev
	ln -s -f gcc-5 /usr/bin/gcc
	
gcc6:  # sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
	apt-get update
	apt-get install gcc-6 g++-6 gcc-6-multilib g++-6-multilib build-essential libssl-dev
	ln -s -f gcc-6 /usr/bin/gcc
	
-include $(DEPS)
