.PHONY: all clean distclean test

NODE_DIR := node_modules
NPM_BIN := $(NODE_DIR)/.bin
COFFEE_CC := $(NPM_BIN)/coffee
NODE_UNIT := $(NPM_BIN)/nodeunit
JISON := $(NPM_BIN)/jison

DEPS := $(COFFEE_CC) $(NODE_UNIT) $(JISON)

SRC_DIR := src src/grammars
SRC_IN := $(wildcard $(addsuffix /*.coffee, $(SRC_DIR)))
SRC_OUT := $(SRC_IN:%.coffee=%.js)

GRAMMAR_DIR := src/grammars
GRAMMARS := $(wildcard $(GRAMMAR_DIR)/*.y)
LEXERS := $(wildcard $(GRAMMAR_DIR)/*.l)
PARSERS := $(GRAMMARS:%.y=%.tab.js)

TEST_DIR := test
TEST_IN := $(wildcard $(TEST_DIR)/*.coffee)
TEST_OUT := $(TEST_IN:%.coffee=%.js)
TEST_MAPS := $(TEST_OUT:%.js=%.js.map)

OUT := $(SRC_OUT) $(PARSERS)
MAPS := $(SRC_OUT:%.js=%.js.map)

all: $(SRC_OUT) $(PARSERS)

clean:
	rm -f $(SRC_OUT) $(TEST_OUT)
	rm -f $(MAPS) $(TEST_MAPS)
	rm -f $(PARSERS)

distclean: clean
	rm -rf $(NODE_DIR)

test: all $(TEST_OUT) $(NODE_UNIT)
ifeq ($(DEBUG),1)
	node-inspector &
	node --debug-brk $(NODE_UNIT) $(TEST_OUT)
else
	$(NODE_UNIT) $(TEST_OUT)
endif

%.js: %.coffee $(COFFEE_CC)
	$(COFFEE_CC) -bcm --no-header $<

JISON_WRAPPER := jison-wrapper.sh
%.tab.js: %.y %.l $(JISON)
	$(JISON_WRAPPER) $@ $^

$(DEPS):
	npm install
