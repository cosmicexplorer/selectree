.PHONY: all test clean

CXX := clang++

CFLAGS := -Wall -Wextra -Werror -std=c++14 -g -O0
LDFLAGS :=

TEMPLATE_SRC := $(wildcard *.tpp *.hpp)

TEST_SRC := main.cpp
TEST_OUT := $(TEST_SRC:%.cpp=%.o)
TEST_BIN := main

all:

test: $(TEST_BIN)
	$(TEST_BIN)

clean:
	rm -f $(TEST_OUT)
	rm -f $(TEST_BIN)

%.o: %.cpp $(TEMPLATE_SRC)
	$(CXX) -c $< $(CFLAGS) -o $@

$(TEST_BIN): $(TEST_OUT)
	$(CXX) $^ -o $@ $(LDFLAGS)
