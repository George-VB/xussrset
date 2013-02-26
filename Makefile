#
# This file is part of the NML build framework
# NML build framework is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
# NML build framework is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with NML build framework. If not, see <http://www.gnu.org/licenses/>.
#

# Definition of the grfs
GRF_FILE            := xussr.grf
REPO_NAME           := xUSSR Trainset
MAIN_SRC_FILE       := xussr.pnml
# GFX_LIST_FILES      := gfx/png_source_list

# Directory structure
SRC_DIR             := src
DOC_DIR             := docs
SCRIPT_DIR          := build-common
LANG_DIR            := lang

# Documentation files:
DOC_FILES = docs/readme.txt docs/license.txt docs/changelog.txt docs/readme_ru.txt docs/changelog_ru.txt

# List of all files which will get shipped
# DOC_FILES = readme, changelog and license
# GRF_FILENAME = MAIN_FILENAME_SRC with the extention .grf
# Add any additional, not usual files here, too, including
# their relative path to the root of the repository
BUNDLE_FILES           = $(GRF_FILE) $(DOC_FILES)

# Replacement strings in the source and in the documentation
# You may only change the values, not add new definitions
# (unless you know where to add them in other places, too)
REPLACE_TITLE       := {{GRF_TITLE}}
REPLACE_GRFID       := {{GRF_ID}}
REPLACE_REVISION    := {{REPO_REVISION}}
REPLACE_FILENAME    := {{FILENAME}}
REPLACE_MD5SUM      := {{GRF_MD5}}

# target 'all' must be first target
all: grf doc bundle_tar

# general definitions (no rules!)
-include Makefile_dist
.PHONY: all clean distclean mrproper depend docs test bundle bundle_bsrc bundle_bzip bundle_gsrc bundle_src bundle_tar bundle_xsrc bundle_xz bundle_zip bundle_zsrc check addcheck

# We want to disable the default rules. It's not c/c++ anyway
.SUFFIXES:

# Don't delete intermediate files
.PRECIOUS: %.nml %.scm %.png
.SECONDARY: %.nml %.scm %.png

################################################################
# Programme definitions / search paths
################################################################
MAKE           ?= make
MAKE_FLAGS     ?= -r

NML            ?= $(shell which nmlc 2>/dev/null)
NML_FLAGS      ?= -c

CC             ?= $(shell which gcc 2>/dev/null)
CC_FLAGS       ?= -C -E - <

# Macs have a different md5 command than linux or mingw envirnoment:
MD5SUM         ?= $(shell [ "$(OSTYPE)" = "Darwin" ] && echo "md5" || echo "md5sum")
MD5SUM_FLAGS   ?= $(shell [ "$(OSTYPE)" = "Darwin" ] && echo "-r" || echo "")

AWK            ?= awk

GREP           ?= grep

HG             ?= $(shell hg st >/dev/null 2>/dev/null && which hg 2>/dev/null)

UNIX2DOS       ?= $(shell which unix2dos 2>/dev/null)
UNIX2DOS_FLAGS ?= $(shell [ -n $(UNIX2DOS) ] && $(UNIX2DOS) -q --version 2>/dev/null && echo "-q" || echo "")

################################################################
# Get the Repository revision, tags and the modified status
# The displayed name within OpenTTD / TTDPatch
# Looks like either
# a nightly build:                 GRF's Name nightly-r51
# a release build (taged version): GRF's Name 0.1
################################################################
# This must be conditional declarations, or building from the tar.gz won't work anymore
DEFAULT_BRANCH_NAME ?=

# HG revision
REPO_REVISION  ?= $(shell $(HG) id -n | cut -d+ -f1)

# Whether there are local changes
REPO_MODIFIED  ?= $(shell [ "`$(HG) id | cut -c13`" = "+" ] && echo "M" || echo "")

# Branch name
REPO_BRANCH    ?= $(shell $(HG) id -b | sed "s/default/$(DEFAULT_BRANCH_NAME)/")

# Any tag which is not 'tip'
REPO_TAGS      ?= $(shell $(HG) id -t | grep -v "tip")

# Filename addition, if we're not building the default branch
REPO_BRANCH_STRING ?= $(shell if [ "$(REPO_BRANCH)" = "$(DEFAULT_BRANCH_NAME)" ]; then echo ""; else echo "$(REPO_BRANCH)-"; fi)

# The shown version is either a tag, or in the absence of a tag the revision.
REPO_VERSION_STRING ?= $(shell [ -n "$(REPO_TAGS)" ] && echo $(REPO_TAGS)$(REPO_MODIFIED) || echo $(REPO_BRANCH_STRING)r$(REPO_REVISION)$(REPO_MODIFIED))

# The title consists of name and version
REPO_TITLE     ?= $(REPO_NAME) $(REPO_VERSION_STRING)

NML_FILE           := $(patsubst %.grf,%.nml,$(GRF_FILE))

MIN_COMPATIBLE_REVISION ?= $(REPO_REVISION)

# Remove the @ when you want a more verbose output.
_V ?= @
_E ?= @echo

distclean:: clean
maintainer-clean:: distclean

# target 'depend' (not implemented)
# include $(SCRIPT_DIR)/Makefile_dep
-include Makefile_gfx.dep

# target nml
################################################################
# NML-specific targets and rules
################################################################

nml:
	$(_E) "[CPP] $(NML_FILE)"
	$(_V) cd $(MAIN_SRC_DIR)
	$(_V) $(CC) -D REPO_REVISION=$(REPO_REVISION) -D MIN_COMPATIBLE_REVISION=$(MIN_COMPATIBLE_REVISION) -iquote$(SRC_DIR) $(CC_FLAGS) $(SRC_DIR)/$(MAIN_SRC_FILE) > $(NML_FILE)

clean::
	$(_E) "[CLEAN NML]"
	$(_V)-rm -rf $(NML_FILE)

test::
	$(_E) "nml:                          $(NML) $(NML_FLAGS)"

# target 'gfx' which builds all needed sprites
# Only a special gfx target for gimp exists so far
################################################################
# Targets related to creation of graphics files
################################################################
# Dependency on source list file via dep check
GIMP           ?= $(shell [ `which gimp 2>/dev/null` ] && echo "gimp" || echo "")
GIMP_FLAGS     ?= -n -i -b - <

%.scm: $(SCRIPT_DIR)/gimpscript $(SCRIPT_DIR)/gimp.sed
	$(_E) "[GIMP-SCRIPT] $@"
	$(_V) cat $(SCRIPT_DIR)/gimpscript > $@
	$(_V) cat $(GFX_LIST_FILES) | grep $(patsubst %.scm,%.png,$@) | sed -f $(SCRIPT_DIR)/gimp.sed >> $@
	$(_V) echo "(gimp-quit 0)" >> $@

# create the png file. And make sure it's re-created even when present in the repo
%.png: %.scm
	$(_E) "[GIMP] $@"
	$(_V) $(GIMP) $(GIMP_FLAGS) $< >/dev/null

ifdef $(GFX_LIST_FILES)
Makefile_gfx.dep: $(GFX_LIST_FILES) $(SCRIPT_DIR)/Makefile_gimp
	$(_E) "[GFX-DEP] $@"
	$(_V) echo "" > $@
	$(_V) for j in $(GFX_LIST_FILES); do for i in `cat $$j | grep "\([pP][cCnN][xXgG]\)" | cut -d\  -f1 | sed "s/\.\([pP][cCnN][xXgG]\)//"`; do echo "$$i.scm: $$j" >> $@; echo "gfx: $$i.png" >> $@; done; done
	$(_V) cat $(GFX_LIST_FILES) | grep "\([pP][cCnN][xXgG]\)" | sed "s/[ ] */ /g" | cut -d\  -f1-2 | sed "s/ /: /g" >> $@
endif

ifdef $(GFX_LIST_FILES)
gfx: Makefile_gfx.dep
else
gfx:
endif

maintainer-clean::
	$(_E) "[MAINTAINER CLEAN GFX]"
	$(_V) rm -rf Makefile_gfx.dep
ifdef $(GFX_LIST_FILES)
	$(_V) for j in $(GFX_LIST_FILES); do for i in `cat $$j | grep "\([pP][cCnN][xXgG]\)" | cut -d\  -f1 | sed "s/\.\([pP][cCnN][xXgG]\)//"`; do rm -rf $$i.scm; rm -rf $$i.png; done; done
endif

#####################################################
# target 'lng' which builds the lang/*.lng files
#####################################################
lng: custom_tags.txt

custom_tags.txt: nml
	$(_E) "[LNG] $@"
	$(_V) echo "VERSION  :$(REPO_VERSION_STRING)" > $@
	$(_V) echo "TITLE    :$(REPO_TITLE)" >> $@
	$(_V) echo "FILENAME :$(GRF_FILE)" >> $@

clean::
	$(_E) "[CLEAN LNG]"
	$(_V)-rm -rf custom_tags.txt

################################################################
# grf - specific rules
# target 'grf' which builds the grf from the nml
################################################################

grf $(GRF_FILE): gfx nml lng
	$(_E) "[NML] $(GRF_FILE)"
	$(_V) $(NML) $(NML_FLAGS) --grf $(GRF_FILE) $(NML_FILE)

$(MD5_FILENAME) $(MD5_SRC_FILENAME): $(GRF_FILE)
	$(_E) "[MD5] $@"
	$(_V) $(MD5SUM) $(MD5SUM_FLAGS) $< | sed "s/  / /;s/ /  /" > $@
md5: $(MD5_FILENAME)

clean::
	$(_E) "[CLEAN GRF]"
	$(_V)-rm -rf $(GRF_FILE)
	$(_V)-rm -rf $(GRF_FILE).cache
	$(_V)-rm -rf $(GRF_FILE).cacheindex
	$(_V)-rm -rf parsetab.py
	$(_V)-rm -rf $(MD5_FILENAME)

maintainer-clean::
	$(_E) "[MAINTAINER-CLEAN GRF]"
	$(_V) -rm -rf $(MD5_SRC_FILENAME)

################################################################
# Documentation targets
# target 'doc' which builds the docs
################################################################

%.txt: %.ptxt
	$(_E) "[DOC] $@"
	$(_V) cat $< \
		| sed -e "s/$(REPLACE_TITLE)/$(REPO_TITLE)/" \
		| sed -e "s/$(REPLACE_GRFID)/$(GRF_ID)/" \
		| sed -e "s/$(REPLACE_REVISION)/$(REPO_REVISION)/" \
		| sed -e "s/$(REPLACE_FILENAME)/$(OUTPUT_FILENAME)/" \
		> $@
	$(_V) [ -z "$(UNIX2DOS)" ] || $(UNIX2DOS) $(UNIX2DOS_FLAGS) $@

doc: $(DOC_FILES)

clean::
	$(_E) "[CLEAN DOC]"
	$(_V) -for i in $(patsubst %.txt,%,$(DOC_FILES)); do [ -f $$i.ptxt ] && [ -f $$i.txt ] && rm -rf $$i.txt || true; done

################################################################
# Bundle targets
# Binary bundle targets
################################################################
# target 'bundle' and bundle_xxx which builds the distribution files
# and the distribution bundles like bundle_tar, bundle_zip, ...

# Programme definitions

TAR            ?= $(shell which tar 2>/dev/null)
TAR_FLAGS      ?= -cf

ZIP            ?= $(shell which zip 2>/dev/null)
ZIP_FLAGS      ?= -9rq

GZIP           ?= $(shell which gzip 2>/dev/null)
GZIP_FLAGS     ?= -9f

BZIP           ?= $(shell which bzip2 2>/dev/null)
BZIP_FLAGS     ?= -9fk

XZ             ?= $(shell which xz 2>/dev/null)
XZ_FLAGS       ?= -efk

# OSX has nice extended file attributes which create their own file within tars. We don't want those, thus don't copy them
CP_FLAGS       ?= $(shell [ "$(OSTYPE)" = "Darwin" ] && echo "-rfX" || echo "-rf")


# Rules on how to generate filenames. Usually no need to change

# Define how the displayed name and the filename of the bundled grf shall look like:
# The result will either be
# nightly build:                   mynewgrf-nightly-r51
# a release build (tagged version): mynewgrf-0.1
# followed by an M, if the source repository is not a clean version.

# Common to all filenames
FILENAME_STUB      := $(firstword $(basename $(GRF_FILE)))

DIR_BASE           := $(FILENAME_STUB)-
DIR_NAME           := $(shell [ -n "$(REPO_TAGS)" ] && echo $(DIR_BASE)$(REPO_VERSION_STRING) || echo $(FILENAME_STUB))
VERSIONED_FILENAME := $(DIR_BASE)$(REPO_VERSION_STRING)
DIR_NAME_SRC       := $(VERSIONED_FILENAME)-source

TAR_FILENAME       := $(DIR_NAME).tar
BZIP_FILENAME      := $(TAR_FILENAME).bz2
GZIP_FILENAME      := $(TAR_FILENAME).gz
XZ_FILENAME        := $(TAR_FILENAME).xz
ZIP_FILENAME       := $(VERSIONED_FILENAME).zip
MD5_FILENAME       := $(DIR_NAME).md5
MD5_SRC_FILENAME   := $(DIR_NAME).check.md5
# customly defined tags. Don't change the filename.

# Bundle directory
$(DIR_NAME): grf doc
	$(_E) "[BUNDLE] $@"
	$(_V) if [ -e $@ ]; then rm -rf $@; fi
	$(_V) mkdir $@
	$(_V) -for i in $(BUNDLE_FILES); do cp $(CP_FLAGS) $$i $@; done

$(DIR_NAME).tar: $(DIR_NAME)
	$(_E) "[BUNDLE TAR] $@"
	$(_V) $(TAR) $(TAR_FLAGS) $@ $<

bundle_tar: $(DIR_NAME).tar
bundle_zip: $(DIR_NAME).tar.zip
%.zip: $(DIR_NAME).tar
	$(_E) "[BUNDLE ZIP] $@"
	$(_V) $(ZIP) $(ZIP_FLAGS) $@ $< >/dev/null
bundle_bzip: $(DIR_NAME).tar.bz2
%.tar.bz2: %.tar
	$(_E) "[BUNDLE BZIP] $@"
	$(_V) $(BZIP) $(BZIP_FLAGS) $^
bundle_gzip: $(DIR_NAME).tar.gz
# gzip has no option -k, so we cat the tar to keep it
%.tar.gz: %.tar
	$(_E) "[BUNDLE GZIP] $@"
	$(_V) cat $^ | $(GZIP) $(GZIP_FLAGS) > $@
bundle_xz: $(DIR_NAME).tar.xz
%.tar.xz: %.tar
	$(_E) "[BUNDLE XZ] $@"
	$(_V) $(XZ) $(XZ_FLAGS) $^

clean::
	$(_E) "[CLEAN BUNDLE]"
	$(_V) -rm -rf $(DIR_NAME)
	$(_V) -rm -rf $(DIR_NAME).tar
	$(_V) -rm -rf $(DIR_NAME).tar.zip
	$(_V) -rm -rf $(DIR_NAME).tar.gz
	$(_V) -rm -rf $(DIR_NAME).tar.bz2
	$(_V) -rm -rf $(DIR_NAME).tar.xz

################################################################
# Bundle source targets
# target 'bundle_src which builds source bundle
################################################################
RE_FILES_NO_SRC_BUNDLE = ^.devzone|^.hg

# OSX md5 programm generates slightly different output. Aleviate that by throwing some sed on all output:
check: $(MD5_FILENAME)
	$(_V) if [ -f $(MD5_SRC_FILENAME) ]; then echo "[CHECKING md5sums]"; else echo "Required file '$(MD5_SRC_FILENAME)' which to test against not found!"; false; fi
	$(_V) if [ -z "`diff $(MD5_FILENAME) $(MD5_SRC_FILENAME)`" ]; then echo "No differences in md5sums"; else echo "Differences in md5sums:"; echo "`diff $(MD5_FILENAME) $(MD5_SRC_FILENAME)`"; false; fi

$(DIR_NAME_SRC).tar: $(DIR_NAME_SRC)
	$(_E) "[BUNDLE SRC]"
	$(_V) $(HG) archive -t tar $<.tar
	$(_V) $(TAR) -uf $@ $^

bundle_src: $(DIR_NAME_SRC).tar

bundle_bsrc: $(DIR_NAME_SRC).tar.bz2
bundle_gsrc: $(DIR_NAME_SRC).tar.gz
bundle_xsrc: $(DIR_NAME_SRC).tar.xz
bundle_zsrc: $(DIR_NAME_SRC).tar.zip

# Addition to config for tar releases
Makefile.fordist:
	$(_V) echo '################################################################' > $@
	$(_V) echo '# Definitions needed for tar releases' >> $@
	$(_V) echo '# This part is automatically generated' >> $@
	$(_V) echo '################################################################' >> $@
	$(_V) echo 'REPO_REVISION := $(REPO_REVISION)' >> $@
	$(_V) echo 'REPO_BRANCH := $(REPO_BRANCH)' >> $@
	$(_V) echo 'REPO_MODIFIED := $(REPO_MODIFIED)' >> $@
	$(_V) echo 'REPO_TAGS    := $(REPO_TAGS)'    >> $@
	$(_V) echo 'HG := :' >> $@

ifneq ("$(strip $(HG))",":")
$(DIR_NAME_SRC): $(MD5_SRC_FILENAME) Makefile.fordist
	$(_E) "[ASSEMBLING] $(DIR_NAME_SRC)"
	$(_V)-rm -rf $@
	$(_V) mkdir $@
	$(_V) cp $(CP_FLAGS) $(MD5_SRC_FILENAME) $(DIR_NAME_SRC)
	$(_V) cp $(CP_FLAGS) Makefile.fordist $@/Makefile.dist
else
$(DIR_NAME_SRC):
	$(_E) "Source releases can only be made from a hg checkout."
	$(_V) false
endif

clean::
	$(_E) "[CLEAN BUNDLE SRC]"
	$(_V) -rm -rf $(DIR_NAME_SRC)
	$(_V) -rm -rf $(DIR_NAME_SRC).tar
	$(_V) -rm -rf Makefile.fordist

maintainer-clean::
	$(_E) "[MAINTAINER-CLEAN BUNDLE SRC]"
	$(_V) -rm -rf $(MD5_SRC_FILENAME)

# target 'install' which installs the grf
################################################################
# Install targets
################################################################
################################################################
# OS-specific definitions and paths
################################################################
PROJECT_NAME := $(basename $(firstword $(GRF_FILE)))

# If we are not given an install dir explicitly we'll try to
#    find the default one for the OS we have
ifndef $(INSTALL_DIR)

# Determine the OS we run on and set the default install path accordingly
OSTYPE:=$(shell uname -s)

ifeq ($(OSTYPE),Darwin)
INSTALL_DIR :=$(HOME)/Documents/OpenTTD/newgrf/$(PROJECT_NAME)
endif

ifeq ($(shell echo "$(OSTYPE)" | cut -d_ -f1),MINGW32)
# If CC has been set to the default implicit value (cc), check if it can be used. Otherwise use a saner default.
ifeq "$(origin CC)" "default"
	CC=$(shell which cc 2>/dev/null && echo "cc" || echo "gcc")
endif
WIN_VER = $(shell echo "$(OSTYPE)" | cut -d- -f2 | cut -d. -f1)
ifeq ($(WIN_VER),5)
	INSTALL_DIR :=C:\Documents and Settings\All Users\Shared Documents\OpenTTD\newgrf\$(PROJECT_NAME)
else
	INSTALL_DIR :=C:\Users\Public\Documents\OpenTTD\newgrf\$(PROJECT_NAME)
endif
endif

ifeq ($(shell echo "$(OSTYPE)" | cut -d_ -f1),CYGWIN)
INSTALL_DIR :=$(shell cygpath -A -O)/OpenTTD/newgrf/$(PROJECT_NAME)
endif

# If non of the above matched, we'll assume we're on a unix-like system
ifeq ($(OSTYPE),Linux)
INSTALL_DIR := $(HOME)/.openttd/newgrf/$(PROJECT_NAME)
endif

endif
DOCDIR ?= $(INSTALL_DIR)

install: $(DIR_NAME).tar
ifeq ($(INSTALL_DIR),"")
	$(_E) "No install dir defined! Aborting"
	$(_V) false
endif
	$(_E) "[INSTALL] to $(INSTALL_DIR)"
	$(_V) install -d $(INSTALL_DIR)
	$(_V) install -m644 $< $(INSTALL_DIR)
ifndef DO_NOT_INSTALL_DOCS
ifneq ($(filter-out $(LICENSE_FILE) $(CHANGELOG_FILE),$(DOC_FILES)),)
	$(_E) [INSTALL] docs to $(DOCDIR)
	$(_V) install -d $(DOCDIR)
	$(_V) install -m644 $(filter-out $(LICENSE_FILE) $(CHANGELOG_FILE),$(DOC_FILES)) $(DOCDIR)
endif
endif
ifndef DO_NOT_INSTALL_LICENSE
ifneq ($(LICENSE_FILE),)
	$(_E) [INSTALL] license to $(DOCDIR)
	$(_V) install -d $(DOCDIR)
	$(_V) install -m644 $(LICENSE_FILE) $(DOCDIR)
endif
endif
ifndef DO_NOT_INSTALL_CHANGELOG
ifneq ($(CHANGELOG_FILE),)
	$(_E) [INSTALL] changelog to $(DOCDIR)
	$(_V) install -d $(DOCDIR)
	$(_V) install -m644 $(CHANGELOG_FILE) $(DOCDIR)
endif
endif

$(INSTALL_DIR):
	$(_E) "[WRITING]"
	$(_V) mkdir -p $(INSTALL_DIR)

# misc. convenience targets like 'langcheck'
-include $(SCRIPT_DIR)/Makefile_misc

help:
	$(_E) "all:         Build the entire NewGRF and its documentation"
	$(_E) "install:     Install into the default NewGRF directory ($(INSTALL_DIR))"
	$(_E) "doc:         Build the documentation ($(DOC_FILES))"
ifdef $(GFX_LIST_FILES)
	$(_E) "gfx:         Build the graphics dependencies"
endif
	$(_E) "grf:         Build the grf file only ($(GRF_FILE))"
	$(_E) "nml:         Generate the combined nml file only ($(NML_FILE))"
	$(_E) "lng:         Generate the language file(s) and custom_tags.txt"
	$(_E)
	$(_E) "clean:       Clean all built files"
	$(_E) "distclean:   Clean really everything"
	$(_E) "maintainer-clean:"
	$(_E) "             Reset the repository to prestine state"
	$(_E)
	$(_E) "Bundles for distribution:"
	$(_E) "bundle:      Build the distribution bundle in $(DIR_NAME)"
	$(_E) "bundle_tar:  Build the distritubion bundle as tar archive ($(DIR_NAME).tar)"
	$(_E) "bundle_zip:  Build the distritubion bundle and compress with zip ($(DIR_NAME).tar.zip)"
	$(_E) "bundle_xz:   Build the distritubion bundle and compress with xz ($(DIR_NAME).tar.xz)"
	$(_E) "bundle_gzip: Build the distritubion bundle and compress with gzip ($(DIR_NAME).tar.gz)"
	$(_E) "bundle_bzip: Build the distribution bundle and compress with bzip2 ($(DIR_NAME).tar.bz2)"
	$(_E) "bundle_src:  Build the source bundle as tar archive for distribution"
	$(_E) "bundle_bsrc: Build the source bundle as tar archive compressed with bzip2"
	$(_E) "bundle_gsrc: Build the source bundle as tar archive compressed with gzip"
	$(_E) "bundle_xsrc: Build the source bundle as tar archive compressed with xz"
	$(_E) "bundle_zsrc: Build the source bundle as tar archive compressed with zip"
	$(_E)
	$(_E) "Valide command line variables are:"
	$(_E) "Helper programmes:"
	$(_E) "MAKE MAKE_FLAGS.        defaults: $(MAKE) $(MAKE_FLAGS)"
	$(_E) "CC CC_FLAGS.            defaults: $(CC) $(CC_FLAGS)"
	$(_E) "AWK                     defaults: $(AWK)"
	$(_E) "GREP                    defaults: $(GREP)"
	$(_E) "MD5SUM MD5SUM_FLAGS.    defaults: $(MD5SUM) $(MD5SUM_FLAGS)"
	$(_E) "UNIX2DOS UNIX2DOS_FLAGS defaults: $(UNIX2DOS) $(UNIX2DOS_FLAGS)"
	$(_E) "GIMP GIMP_FLAGS         defaults: $(GIMP) $(GIMP_FLAGS)"
	$(_E) "CP_FLAGS (for cp command):        $(CP_FLAGS)"
	$(_E)
	$(_E) "NML NML_FLAGS.          defaults: $(NML) $(NML_FLAGS)"
	$(_E)
	$(_E) "archive and compression programmes:"
	$(_E) "TAR TAR_FLAGS   .       defaults: $(TAR) $(TAR_FLAGS)"
	$(_E) "ZIP ZIP_FLAGS.          defaults: $(ZIP) $(ZIP_FLAGS)"
	$(_E) "GZIP GZIP_FLAGS         defaults: $(GZIP) $(GZIP_FLAGS)"
	$(_E) "BZIP BZIP_FLAGS         defaults: $(BZIP) $(BZIP_FLAGS)"
	$(_E) "XZ XZ_FLAGS             defaults: $(XZ) $(XZ_FLAGS)"
	$(_E)
	$(_E) "INSTALL_DIR             defaults: $(INSTALL_DIR)"
	$(_E) "    Sets the default installation directory for NewGRFs"

