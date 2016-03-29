namespace selectree
{
namespace css
{
#include "css.flex.hpp"
}
}

#include <sstream>

namespace selectree
{
namespace css
{
std::string generate_matcher(std::string input)
{
  /* FIXME: make this reentrant! http://www.lemoda.net/c/reentrant-parser/ */
  std::stringstream stream(input);
  std::stringstream out;
  css_yy_FlexLexer lexer(stream, out);
  lexer.yylex();
  return out.str();
}
}
}
