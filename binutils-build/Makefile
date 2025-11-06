#
# Makefile to compile binutils cross
#
# Use SRC_DIR to alter the path of the source (default ../binutils)
#
# Use BINUTILS_VERSION to specify the version (alters the name of the
# created drawer)

ifeq ($(BINUTILS_VERSION),)
$(error BINUTILS_VERSION is a required variable)
endif

SRC_DIR=../binutils/repo
CROSS_BUILD_DIR=cross-$(BINUTILS_VERSION)
NATIVE_BUILD_DIR=cross-$(BINUTILS_VERSION)
PREFIX=/usr/local/amiga
REAL_SRC_DIR=$(realpath $(SRC_DIR))

############################
### BEGIN: SETUP OPTIONS ###
############################
ifeq ($(BINUTILS_VERSION),2.23.2)
CROSS_CFLAGS=CFLAGS="					\
				-Wno-switch		\
				-Wno-unused		\
							"
CROSS_CONFIGURE_ARGUMENTS=				\
				--enable-plugins	\
				--target=ppc-amigaos	\
				--prefix=$(PREFIX)
NATIVE_CFLAGS=CFLAGS="					\
				-Wno-switch		\
				-Wno-unused		\
							"
NATIVE_LDFLAGS=LDFLAGS="				\
				-lunix			\
							"
NATIVE_CONFIGURE_ARGUMENTS=				\
				--target=ppc-amigaos	\
				--host=ppc-amigaos	\
				--disable-nls		\
				--prefix=/gcc
else
ifneq ($(BINUTILS_VERSION),2.40)
$(error Unexpected binutils version)
else
CROSS_CFLAGS=CFLAGS="					\
				-Wno-sign-compare	\
							"
CROSS_CONFIGURE_ARGUMENTS=				\
				--disable-plugins	\
				--disable-gdb		\
				--disable-sim		\
				--target=ppc-amigaos	\
				--prefix=$(PREFIX)
NATIVE_CFLAGS=CFLAGS="					\
				-mcrt=clib4		\
				-Wno-sign-compare	\
							"
NATIVE_LDFLAGS=LDFLAGS="				\
				-mcrt=clib4		\
							"
NATIVE_CONFIGURE_ARGUMENTS=				\
				--target=ppc-amigaos	\
				--host=ppc-amigaos	\
				--disable-plugins	\
				--disable-gdb		\
				--disable-sim		\
				--disable-nls		\
				--prefix=/gcc
endif
endif
############################
### ENDER: SETUP OPTIONS ###
############################

.PHONY: cross native

cross:
	mkdir -p $(CROSS_BUILD_DIR)
	cd $(CROSS_BUILD_DIR);			\
		$(CROSS_CFLAGS)			\
		$(REAL_SRC_DIR)/configure	\
		$(CROSS_CONFIGURE_ARGUMENTS)
	$(MAKE) -C $(CROSS_BUILD_DIR)

native:
	mkdir -p $(NATIVE_BUILD_DIR)
	cd $(NATIVE_BUILD_DIR);			\
		$(NATIVE_LDFLAGS)		\
		$(NATIVE_CFLAGS)		\
		$(REAL_SRC_DIR)/configure	\
		$(NATIVE_CONFIGURE_ARGUMENTS)
	$(MAKE) -C $(NATIVE_BUILD_DIR)
