CC=gcc

THISMACHINE := $(shell uname -srm | sed -e 's/ /-/g')
THISSYSTEM	:= $(shell uname -s)

TARGETLIB   ?= libjudy.$(THISSYSTEM).a
VERSION     ?= "0.1.0"
PACKAGEDIR  ?= ./../_hbpkg/$(THISMACHINE)/libjudy.$(VERSION)

TARGET      := libjudy_test


SRCDIR      := src
INCDIR      := ./include
BUILDDIR    := build
PRODUCTDIR  := bin
SRCEXT      := c
DEPEXT      := d
OBJEXT      := o

#CFLAGS      := -std=gnu99 -O -g -Wall
CFLAGS      := -std=gnu99 -O3
LIB         := ./
DEF         := 
INC         := -I$(SRCDIR) $(LIB:%=-I%)
INCDEP      := -I$(INCDIR) $(LIB:%=-I%) 
          
SOURCES     := $(shell find $(SRCDIR) -type f -name "*.$(SRCEXT)")
OBJECTS     := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.$(OBJEXT)))


all: directories $(TARGET)
lib: directories $(TARGETLIB)
remake: cleaner all


install:
	@mkdir -p $(PACKAGEDIR)
	@cp $(SRCDIR)/judy.h $(PACKAGEDIR)/
	@cp -R $(PRODUCTDIR)/* $(PACKAGEDIR)/
	@rm -f $(PACKAGEDIR)/../libjudy
	@ln -s libjudy.$(VERSION) ./$(PACKAGEDIR)/../libjudy


#Make the Directories
directories:
	@mkdir -p $(BUILDDIR)
	@mkdir -p $(PRODUCTDIR)

#Clean only Objects
clean:
	@$(RM) -rf $(BUILDDIR)

#Full Clean, Objects and Binaries
cleaner: clean
	@$(RM) -rf $(BUILDDIR)
	@$(RM) -rf $(PRODUCTDIR)

# Pull in dependency info for *existing* .o files
-include $(OBJECTS:.$(OBJEXT)=.$(DEPEXT))

# Build of the test app with static lib
libjudy_test: $(TARGETLIB)
	$(CC) $(CFLAGS) $(DEF) $(INC) -c -o $(BUILDDIR)/libjudy-test.o ./test/libjudy-test.c
	$(CC) $(CFLAGS) $(DEF) $(BUILDDIR)/libjudy-test.o $(INC) $(LIB:%=-L%) -ljudy -o $(PRODUCTDIR)/libjudy_test

# Build the static library
# Note: testing with libtool now, which may be superior to ar
libjudy.Darwin.a: $(OBJECTS)
	libtool -o $(PRODUCTDIR)/libjudy.a -static $(OBJECTS)

libjudy.Linux.a: $(OBJECTS)
	$(eval LIBTOOL_OBJ := $(shell find $(BUILDDIR) -type f -name "*.$(OBJEXT)"))
	libtool --tag=CC --mode=link $(CC) -all-static -g -O3 $(INC) $(LIB) -o $(PRODUCTDIR)/libjudy.a $(OBJECTS)

# Compile
$(BUILDDIR)/%.$(OBJEXT): $(SRCDIR)/%.$(SRCEXT)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(DEF) $(INC) -c -o $@ $<
	@$(CC) $(CFLAGS) $(DEF) $(INCDEP) -MM $(SRCDIR)/$*.$(SRCEXT) > $(BUILDDIR)/$*.$(DEPEXT)
	@cp -f $(BUILDDIR)/$*.$(DEPEXT) $(BUILDDIR)/$*.$(DEPEXT).tmp
	@sed -e 's|.*:|$(BUILDDIR)/$*.$(OBJEXT):|' < $(BUILDDIR)/$*.$(DEPEXT).tmp > $(BUILDDIR)/$*.$(DEPEXT)
	@sed -e 's/.*://' -e 's/\\$$//' < $(BUILDDIR)/$*.$(DEPEXT).tmp | fmt -1 | sed -e 's/^ *//' -e 's/$$/:/' >> $(BUILDDIR)/$*.$(DEPEXT)
	@rm -f $(BUILDDIR)/$*.$(DEPEXT).tmp

# Non-File Targets
.PHONY: all lib remake clean cleaner resources

