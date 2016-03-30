%skeleton "lalr1.cc"
%require "3.0.4"
%define api.namespace {selectree::css}
%define api.pure full
%{
#include <string>
%}

%token <int> INT
%token <float> FLOAT
%token <std::string> STRING

%%

snazzle:
        INT snazzle { yyout << "bison int: " << $1 << std::endl; }
        | FLOAT snazzle { yyout << "bison float: " << $1 << std::endl; }
        | STRING snazzle { yyout << "bison string: " << $1 << std::endl; }
        | %empty { yyout << "eof!" << std::endl; }

%%
