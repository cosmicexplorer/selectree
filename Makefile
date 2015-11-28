.PHONY: all clean distclean test

NODE_DIR := node_modules
NPM_BIN := $(NODE_DIR)/.bin
COFFEE_CC := $(NPM_BIN)/coffee
NODE_UNIT := $(NPM_BIN)/nodeunit

DEPS := $(COFFEE_CC) $(NODE_UNIT)

SRC_DIR := src
SRC_IN := $(wildcard $(SRC_DIR)/*.coffee)
SRC_OUT := $(SRC_IN:%.coffee=%.js)

TEST_DIR := test
TEST_IN := $(wildcard $(TEST_DIR)/*.coffee)
TEST_OUT := $(TEST_IN:%.coffee=%.js)

all: $(SRC_OUT)

clean:
	rm -f $(SRC_OUT) $(TEST_OUT)

distclean: clean
	rm -rf $(NODE_DIR)

test: all $(TEST_OUT) $(NODE_UNIT)
	$(NODE_UNIT) $(TEST_OUT)

%.js: %.coffee $(COFFEE_CC)
	$(COFFEE_CC) -c $<

$(DEPS):
	npm install
