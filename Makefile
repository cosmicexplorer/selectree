.PHONY: all test clean

CXX := clang++
FLEX := flex
BISON := bison

FLFLAGS := -+
BSFLAGS := -L C++

CXXFLAGS := -Wall -Wextra -Werror -std=c++14 -g -O0
LDFLAGS :=

TEMPLATE_SRC := $(wildcard *.tpp *.hpp)
SRC := $(wildcard *.cpp)
OUT := $(SRC:%.cpp=%.o)

GRAMMARS_DIR := grammars

FLEX_IN := $(wildcard $(GRAMMARS_DIR)/*.l)
FLEX_H := $(FLEX_IN:%.l=%.flex.hpp)
FLEX_SRC := $(FLEX_IN:%.l=%.flex.cpp)
FLEX_OUT := $(FLEX_SRC:%.cpp=%.o)

BISON_IN := $(wildcard $(GRAMMARS_DIR)/*.y)
BISON_H := $(BISON_IN:%.y=%.bison.hpp)
BISON_SRC := $(BISON_IN:%.y=%.bison.cpp)
BISON_OUT := $(BISON_SRC:%.cpp=%.o)

.SECONDARY: $(FLEX_H) $(FLEX_SRC) $(BISON_H) $(BISON_SRC)

TEST_SRC := main.cpp
TEST_OUT := $(TEST_SRC:%.cpp=%.o)
TEST_BIN := main

all: $(TEST_BIN)

test: all
	$(TEST_BIN)

clean:
	rm -f $(TEST_OUT)
	rm -f $(TEST_BIN)
	rm -f $(FLEX_H) $(FLEX_SRC) $(FLEX_OUT)

%.flex.hpp: %.l
	$(FLEX) $(FLFLAGS) -o $(@:%.hpp=%.cpp) --header-file=$@ \
		--prefix=$(<:$(GRAMMARS_DIR)/%.l=selectree_%_) $<

%.flex.cpp: %.flex.hpp
	touch $@

# also generates stack.hh
%.bison.hpp: %.y
	$(BISON) $(BSFLAGS) \
		-Dapi.prefix={$(<:$(GRAMMARS_DIR)/%.y=selectree_%_)} \
		--defines=$@ -o $(@:%.hpp=%.cpp) $<

%.bison.cpp: %.bison.hpp
	touch $@

$(GRAMMARS_DIR)/%.o: $(GRAMMARS_DIR)/%.cpp
	$(CXX) -c $< $(CXXFLAGS) -o $@

%.o: %.cpp $(TEMPLATE_SRC) $(FLEX_H) $(BISON_H)
	$(CXX) -c $< $(CXXFLAGS) -o $@

$(TEST_BIN): $(TEST_OUT) $(FLEX_OUT) $(BISON_OUT) $(OUT)
	$(CXX) $^ -o $@ $(LDFLAGS)
