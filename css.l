%{
%}
%%
[ \t\n]         ;
[0-9]+\.[0-9]+  { std::cout << "Found a floating-point number:" << yytext << std::endl; }
[0-9]+          { std::cout << "Found an integer:" << yytext << std::endl; }
[a-zA-Z0-9]+    { std::cout << "Found a string: " << yytext << std::endl; }
%%
