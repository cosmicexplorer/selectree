.PHONY: all test clean

CXX := clang++
FLEX := flex

CFLAGS := -Wall -Wextra -Werror -std=c++14 -g -O0
LDFLAGS := -lfl

TEMPLATE_SRC := $(wildcard *.tpp *.hpp)

FLEX_IN := $(wildcard *.l)
FLEX_H := $(FLEX_IN:%.l=%.flex.hpp)
FLEX_SRC := $(FLEX_IN:%.l=%.flex.cpp)
FLEX_OUT := $(FLEX_SRC:%.cpp=%.o)

TEST_SRC := main.cpp
TEST_OUT := $(TEST_SRC:%.cpp=%.o)
TEST_BIN := main

all:

test: $(TEST_BIN)
	$(TEST_BIN)

clean:
	rm -f $(TEST_OUT)
	rm -f $(TEST_BIN)

%.flex.hpp: %.l
	$(FLEX) -o $(@:%.hpp=%.cpp) -+ --header-file=$(word 1, $@) \
		--prefix=$(@:%.flex.hpp=%_yy_) $<

%.flex.cpp: %.flex.hpp
	touch $@

%.o: %.cpp $(TEMPLATE_SRC) $(FLEX_H)
	$(CXX) -c $< $(CFLAGS) -o $@

$(TEST_BIN): $(TEST_OUT) $(FLEX_OUT)
	$(CXX) $^ -o $@ $(LDFLAGS)
