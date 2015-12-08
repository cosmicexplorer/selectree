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

all: $(SRC_OUT) $(PARSERS)

clean:
	rm -f $(SRC_OUT) $(TEST_OUT)

distclean: clean
	rm -rf $(NODE_DIR)

test: all $(TEST_OUT) $(NODE_UNIT)
	$(NODE_UNIT) $(TEST_OUT)

%.js: %.coffee $(COFFEE_CC)
	$(COFFEE_CC) -bc --no-header $<

JISON_WRAPPER := jison-wrapper.sh
%.tab.js: %.y %.l $(JISON)
	$(JISON_WRAPPER) $@ $^

$(DEPS):
	npm install
