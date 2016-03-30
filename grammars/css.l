%{
#include "css.bison.hpp"
int yyFlexLexer::yywrap() {
    return 1;
}
%}
%%
[ \t\n]         ;
[0-9]+\.[0-9]+  { yylval.fval = atof(yytext); return FLOAT; }
[0-9]+          { yylval.ival = atoi(yytext); return INT; }
[a-zA-Z0-9]+    { yylval.sval = std::string(yytext); return STRING; }
%%
