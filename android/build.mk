ifeq (,$(strip $(NDK)))
$(error NDK is not defined!)
endif

override NDK := $(realpath $(wildcard $(NDK)))

ifeq (,$(strip $(SOURCES)))
$(error SOURCES are not defined!)
endif

ifeq (,$(strip $(HEADERS)))
$(error HEADERS are not defined!)
endif

ifeq (,$(strip $(RESOURCES)))
$(error RESOURCES are not defined!)
endif

ifeq (,$(strip $(TOPDIR)))
$(error TOPDIR is not defined!)
endif

ifeq (,$(strip $(MYDIR)))
$(error MYDIR is not defined!)
endif

FRAMEWORK ?= $(notdir $(MYDIR))

CLANG_VERSION ?= 3.6

ABIS ?= armeabi-v7a armeabi-v7a-hard x86 mips x86_64

# $1: ABI
define commonflags
$(strip \
	-fblocks \
	-fintegrated-as \
	-fpic \
	-O2 -g \
	-Werror \
	-Wno-deprecated-objc-isa-usage \
	-DOBJC_EXPORT= \
	-DGCC_RUNTIME_3 \
	-DPTHREAD_INSIDE_BUILD \
	-DCFNETWORK_INSIDE_BUILD \
	-DCOREFOUNDATION_INSIDE_BUILD \
	-DFOUNDATION_INSIDE_BUILD \
	-DOBJC_INSIDE_BUILD \
	-DPLATFORM_IS_POSIX \
	-DPLATFORM_USES_BSD_SOCKETS \
	-DCOCOTRON_DISALLOW_FORWARDING \
	-I$(NDK)/sources/objc/libobjc2/include \
	-I$(MYDIR)/include \
	-I$(genroot)/include \
)
endef

# $1: ABI
define ldflags
$(strip \
	-Wl,--no-undefined \
	-fpic \
	-O2 -g \
)
endef

#=======================================================================================

empty :=
space := $(empty) $(empty)
comma := ,

define commas-to-spaces
$(strip $(subst $(comma),$(space),$(1)))
endef

define spaces-to-commas
$(strip $(subst $(space),$(comma),$(strip $(1))))
endef

# $1: list
define head
$(firstword $(1))
endef

# $1: list
define tail
$(wordlist 2,$(words $(1)),$(1))
endef

# $1: root directory
# $2: wildcards (*.c, *.h etc)
define rwildcard
$(foreach __d,$(wildcard $(1)*),$(call rwildcard,$(__d)/,$(2)) $(filter $(subst *,%,$(2)),$(__d)))
endef

define rm-if-exists
$(if $(wildcard $(1)),rm -Rf $(wildcard $(1)))
endef

define link
rm -f $(2) && ln -s $(1) $(2)
endef

define hide
$(if $(filter 1,$(V)),,@)
endef

define abis
$(call commas-to-spaces,$(strip $(ABIS)))
endef

define host-os
$(shell uname -s | tr '[A-Z]' '[a-z]')
endef

define host-arch
$(shell uname -m)
endef

define outdir
$(or $(strip $(OUT)),$(MYDIR))
endef

define objroot
$(outdir)/obj
endef

define targetroot
$(outdir)/lib
endef

define genroot
$(outdir)/gen
endef

# $1: ABI
define objdir
$(strip $(if $(strip $(1)),\
    $(objroot)/$(strip $(1)),\
    $(error Usage: call objdir,abi)\
))
endef

# $1: source file
define objfile
$(addsuffix .o,$(subst $(abspath $(TOPDIR))/,,$(abspath $(1))))
endef

# $1: ABI
define objfiles
$(strip \
    $(addprefix $(call objdir,$(1))/,\
        $(foreach __f,$(SOURCES),$(call objfile,$(__f)))\
    )\
)
endef

# $1: ABI
define tcprefix
$(strip $(if $(strip $(1)),\
    $(or \
        $(if $(filter armeabi%,$(1)),arm-linux-androideabi-),\
        $(if $(filter arm64-v8a,$(1)),aarch64-linux-android-),\
        $(if $(filter x86,$(1)),x86-),\
        $(if $(filter x86_64,$(1)),x86_64-),\
        $(if $(filter mips,$(1)),mipsel-linux-android-),\
        $(if $(filter mips64,$(1)),mips64el-linux-android-),\
        $(error Unsupported ABI: '$(1)')\
    ),\
    $(error Usage: call tcprefix,abi)\
))
endef

# $1: ABI
define tcname
$(strip $(if $(strip $(1)),\
    $(or \
        $(if $(filter x86,$(1)),i686-linux-android-),\
        $(if $(filter x86_64,$(1)),x86_64-linux-android-),\
        $(call tcprefix,$(1))\
    ),\
    $(error Usage: call tcname,abi)\
))
endef

# $1: ABI
# $2: GCC version
define gcc-toolchain
$(abspath $(NDK)/toolchains/$(call tcprefix,$(1))$(2)/prebuilt/$(host-os)-$(host-arch))
endef

# $1: ABI
define llvm-tripple
$(strip $(if $(strip $(1)),\
    $(or \
        $(if $(filter armeabi,$(1)),armv5te-none-linux-androideabi),\
        $(if $(filter armeabi-v7a%,$(1)),armv7-none-linux-androideabi),\
        $(if $(filter arm64-v8a,$(1)),aarch64-none-linux-android),\
        $(if $(filter x86,$(1)),i686-none-linux-android),\
        $(if $(filter x86_64,$(1)),x86_64-none-linux-android),\
        $(if $(filter mips,$(1)),mipsel-none-linux-android),\
        $(if $(filter mips64,$(1)),mips64el-none-linux-android),\
        $(error Unsupported ABI: '$(1)')\
    ),\
    $(error Usage: call llvm-tripple,abi)\
))
endef

# $1: ABI
# $2: Toolchain utility name (clang, ar etc)
define tc-bin
$(strip $(if $(and $(strip $(1)),$(strip $(2))),\
    $(strip \
        $(abspath $(NDK))/toolchains/llvm-$(CLANG_VERSION)/prebuilt/$(host-os)-$(host-arch)/bin/$(strip $(2))\
        $(if $(filter clang clang++,$(2)),\
            -target $(call llvm-tripple,$(1))\
            -gcc-toolchain $(call gcc-toolchain,$(1),4.9)\
        )\
    ),\
    $(error Usage: call tc-bin,abi,name)\
))
endef

# $1: ABI
define cc
$(call tc-bin,$(1),clang)
endef

# $1: ABI
define c++
$(call tc-bin,$(1),clang++)
endef

# $1: ABI
define ar
$(call tc-bin,$(1),llvm-ar)
endef

# $1: ABI
# $2: source file
define compiler-for
$(strip $(if $(and $(strip $(1)),$(strip $(2))),\
    $(or \
        $(if $(filter %.c %.m %.s %.S,$(2)),$(call cc,$(1))),\
        $(if $(filter %.cpp %.cc %.mm,$(2)),$(call c++,$(1))),\
        $(error Cannot detect compiler for '$(2)')\
    ),\
    $(error Usage: call compiler-for,abi,source-file)\
))
endef

# $1: ABI
define cflags
$(call commonflags,$(1))
endef

# $1: ABI
define c++flags
$(call commonflags,$(1))
endef

# $1: ABI
define asmflags
$(call commonflags,$(1))
endef

# $1: ABI
# $2: source file
define compiler-flags
$(strip $(if $(and $(strip $(1)),$(strip $(2))),\
    $(or \
        $(if $(filter %.c %.m,$(2)),$(call cflags,$(1))),\
        $(if $(filter %.cpp %.cc %.mm,$(2)),$(call c++flags,$(1))),\
        $(if $(filter %.s %.S,$(2)),$(call asmflags,$(1))),\
        $(error Cannot detect compiler flags for '$(2)')\
    ),\
    $(error Usage: call compiler-for,abi,source-file)\
))
endef

# $1: ABI
define arch-for-abi
$(strip $(if $(filter 1,$(words $(1))),\
    $(or \
        $(if $(filter armeabi%,$(1)),arm),\
        $(if $(filter arm64%,$(1)),arm64),\
        $(if $(filter x86 x86_64 mips mips64,$(1)),$(1)),\
        $(error Unsupported ABI: '$(1)')\
    ),\
    $(error Usage: call arch-for-abi,abi)\
))
endef

# $1: ABI
# $2: list of API levels
define detect-platform
$(strip $(if $(filter 1,$(words $(1))),\
    $(if $(strip $(2)),\
        $(if $(wildcard $(NDK)/platforms/android-$(call head,$(2))/arch-$(call arch-for-abi,$(1))),\
            android-$(call head,$(2)),\
            $(call detect-platform,$(1),$(call tail,$(2)))\
        ),\
        $(error Can not detect sysroot platform for ABI '$(1)')\
    ),\
    $(error Usage: call detect-platform,abi,api-levels)\
))
endef

# $1: ABI
define sysroot
$(strip $(if $(filter 1,$(words $(1))),\
    $(abspath $(NDK)/platforms/$(call detect-platform,$(1),9 21)/arch-$(call arch-for-abi,$(1))),\
    $(error Usage: call sysroot,abi)\
))
endef

define makefiles
$(filter-out %.d,$(MAKEFILE_LIST))
endef

# $1: ABI
# $2: source file
define add-objfile-rule
$$(call objdir,$(1))/$$(call objfile,$(2)): $$(abspath $(2)) $$(makefiles)
	@echo "CC [$(1)] $$(subst $$(abspath $$(TOPDIR))/,,$(2))"
	@mkdir -p $$(dir $$@)
	$$(hide)$$(call compiler-for,$(1),$$<) \
		-MD -MP -MF $$(patsubst %.o,%.d,$$@) \
		$$(call compiler-flags,$(1),$(2)) \
		--sysroot=$$(call sysroot,$(1)) \
		-c -o $$@ $$<
endef

# $1: type (static or shared)
# $2: ABI
define add-target-rule
targetdir = $$(targetroot)/$$(1)/$$(FRAMEWORK).framework
resdir = $$(call targetdir,$$(1))/Resources

__target := $$(call targetdir,$(2))/Versions/A/lib$$(FRAMEWORK).$$(if $$(filter static,$(1)),a,so)

$$(__target): $$(call objfiles,$(2)) $$(RESOURCES) $$(makefiles) | $$(dir $$(__target))
	@echo "$(if $(filter static,$(1)),AR,LD) [$(2)] $$(subst $$(abspath $$(outdir))/,,$$@)"
	@rm -f $$@
	$$(hide)$$(strip $$(if $$(filter static,$(1)),\
		$$(call ar,$(2)) crs $$@ $$(filter-out $$(makefiles),$$^),\
		$$(call cc,$(2)) \
			-shared -Wl,-soname,$$(notdir $$@) \
			$(if $(filter armeabi-v7a-hard,$(2)),-Wl$(comma)--no-warn-mismatch) \
			--sysroot=$$(call sysroot,$(2)) \
			-L$$(call sysroot,$(2))/usr/$(if $(filter x86_64,$(2)),lib64,lib) \
			-L$$(NDK)/sources/crystax/libs/$(2) \
			-L$$(NDK)/sources/objc/libobjc2/libs/$(2) \
			$$(call objfiles,$(2)) \
			$$(call ldflags,$(2)) \
			-lobjc \
			-o $$@ \
		))
	$$(hide)$$(call link,Versions/Current/$$(FRAMEWORK),$$(call targetdir,$(2))/$$(FRAMEWORK))
	$$(hide)$$(call link,A,$$(call targetdir,$(2))/Versions/Current)
	$$(hide)$$(if $$(filter static,$(1)),,$$(call link,$$(notdir $$@),$$(call targetdir,$(2))/Versions/A/$$(FRAMEWORK)))
	$$(hide)rm -Rf $$(call resdir,$(2))
	$$(hide)mkdir -p $$(call resdir,$(2))
	$$(hide)$$(foreach __f,$$(RESOURCES),\
			cp $$(__f) $$(call resdir,$(2))/ || exit 1; \
		)

$$(eval $$(call add-mkdir-rule,$$(dir $$(__target))))

.PHONY: all
all: $$(__target)

.PHONY: $(1)-$(2)
$(1)-$(2): $$(__target)

endef

# $1: type (static or shared)
define add-type-build-rule
.PHONY: $(1)
$(1): gen-sources
	@+$$(foreach __abi,$$(call abis),\
		$$(MAKE) --no-print-directory -C $$(MYDIR) $(1)-$$(__abi) CRYSTAX_EVAL_RULES=yes ABI=$$(__abi) || exit 1; \
	)
endef

define add-all-build-rule
all: gen-sources
	@+$$(foreach __abi,$$(call abis),\
		$$(MAKE) --no-print-directory -C $$(MYDIR) $$(foreach __t,static shared,$$(__t)-$$(__abi)) CRYSTAX_EVAL_RULES=yes ABI=$$(__abi) || exit 1; \
	)
endef

# $1: directory
define add-mkdir-rule
ifeq (,$$(__mkdir_rule_added.$(1)))
$(1):
	$$(hide)mkdir -p $$@

$$(eval __mkdir_rule_added.$(1) := yes)
endif
endef

# $1: source file
# $2: category
define add-gen-header-rule
__relsrc := $$(patsubst $$(TOPDIR)/$(2)/%,%,$(1))
__dstdir := $$(genroot)/include/$(2)

gen-sources: $$(__dstdir)/$$(notdir $$(__relsrc))

$$(__dstdir)/$$(notdir $$(__relsrc)): $(1) | $$(__dstdir)
	@echo "GEN $$(patsubst $$(genroot)/include/%,%,$$@)"
	$$(hide)ln -sf $$< $$@

$$(eval $$(call add-mkdir-rule,$$(__dstdir)))
endef

#=======================================================================================

.PHONY: all
all:

.PHONY: clean
clean:
	$(call rm-if-exists,$(strip \
		$(targetroot) \
		$(objroot) \
		$(genroot) \
	))

.PHONY: gen-sources
gen-sources:

$(foreach __c,\
    $(sort $(foreach __f,$(patsubst $(TOPDIR)/%,%,$(HEADERS)),$(firstword $(subst /, ,$(dir $(__f)))) )),\
    $(foreach __h,$(filter $(TOPDIR)/$(__c)/%,$(HEADERS)),\
        $(eval $(call add-gen-header-rule,$(__h),$(__c)))\
    )\
)

ifeq (yes,$(CRYSTAX_EVAL_RULES))
$(foreach __abi,$(call abis),\
    $(foreach __t,static shared,\
        $(eval $(call add-target-rule,$(__t),$(__abi)))\
    )\
    $(foreach __src,$(SOURCES),\
        $(eval $(call add-objfile-rule,$(__abi),$(__src)))\
    )\
    $(eval sinclude $(call rwildcard,$(call objdir,$(__abi)),*.d))\
)
else
$(eval $(call add-all-build-rule))
$(foreach __t,static shared,\
    $(evall $(call add-type-build-rule,$(__t)))\
)
endif