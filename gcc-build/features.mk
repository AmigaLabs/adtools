MAJOR_VERSION:=$(word 1, $(subst ., , $(VERSION)))

FEATURES=\
	--enable-languages=c,c++,objc,obj-c++  \
	--enable-haifa                         \
	--disable-libstdcxx-pch                \
	--with-dwarf2						\
	--disable-tls

# Check, if major version is greater than or equals to 8
ifeq ($(shell test $(MAJOR_VERSION) -ge 8; echo $$?), 0)
FEATURES+=--enable-threads=amigaos --enable-lto

# Under the amigaos thread model __gthread_cond_t and __gthread_mutex_t are
# native objects, not pthread ones, so libstdc++ must not reach into them with
# pthread_cond_clockwait() -- the structures differ in both size and meaning.
# libstdc++ probes the C library for that function and turns it on wherever it
# links, which is the case for clib4; presetting the cache variable answers the
# probe instead. condition_variable then converts the deadline itself and waits
# through __gthread_cond_timedwait().
export glibcxx_cv_PTHREAD_COND_CLOCKWAIT=no

# Check, if major version is greater than or equals to 11
ifeq ($(shell test $(MAJOR_VERSION) -ge 11; echo $$?), 0)
FEATURES+=--disable-c++tools
endif
endif
