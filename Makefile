
######
# Detect platform
######
OS := $(shell uname -s)
ifneq ($(OS),OS400)
  $(error This Makefile is intended to be run on an IBM i system.)
endif

######
# Bail out if required environment variables are not set properly.
######
ifeq (,$(BUILD_LIBRARY))
  $(error Required variable BUILD_LIBRARY is not set.)
endif
ifneq (1,$(words [$(BUILD_LIBRARY)]))
  $(error BUILD_LIBRARY variable is not set correctly. Set to a valid library name and try again)
endif

######
# Output library.
######
LIBRARY := $(BUILD_LIBRARY)
LIBRARY_PATH := /qsys.lib/$(LIBRARY).lib

######
# Shell configuration.
######
SHELL := /usr/bin/qsh
.ONESHELL:
.SHELLFLAGS = -ec

######
# Utility to set library list.
######
define SET_LIBL
liblist -cd
if liblist | grep -Eiq '^$(LIBRARY)[[:space:]]+'; then
  liblist -d $(LIBRARY)
fi
liblist -af $(LIBRARY)
endef

######
# Utility to output "Creating X..." message and redirect recipe output to log file.
######
define SETUP_LOG
@echo "Creating $1"
touch -C 1208 'tmp/logs/$1.log'
exec > 'tmp/logs/$1.log' 2>&1
endef

######
# Prerun actions.
######
$(info ===)
$(info Target library: $(LIBRARY))
$(info ===)
$(shell rm -rf tmp/logs && /QOpenSys/usr/bin/mkdir -p tmp/logs)

######
# Test data files.
######
define TEST_DATA_FILES
categp.file
custp.file
featuresp.file
ordhdrp.file
orddtlp.file
prodfeatp.file
prodp.file
productsp.file
endef
TEST_DATA_FILES := $(addprefix $(LIBRARY_PATH)/,$(TEST_DATA_FILES))

######
# Build rules.
######

.PHONY: all

all: | $(TEST_DATA_FILES)
	$(call SETUP_LOG,test data)
	$(SET_LIBL)
	for file in $|; do
	  script=$$(basename $$file .file).sql
	  system "runsqlstm srcstmf('data/$$script') commit(*none) naming(*sys)"
	done
