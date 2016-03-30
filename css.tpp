#include "grammars/css.flex.hpp"

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
  parser p();
  return out.str();
}
}
}
