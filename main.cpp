#include "match.hpp"

#include <iostream>
#include <vector>
#include <string>

struct TreeLike {
  int counter;
  std::vector<TreeLike> children_mem;
  std::string name;
  TreeLike(int count, std::vector<TreeLike> children_arg, std::string name_arg)
      : counter(count), children_mem(children_arg), name(name_arg)
  {
  }
  std::string id()
  {
    return std::to_string(counter);
  }
  std::vector<TreeLike> children()
  {
    return children_mem;
  }
  std::string get_name()
  {
    return name;
  }
};

int main()
{
  using selectree::match::Matcher;
  using selectree::match::match;
  TreeLike b(0, {}, "b");
  TreeLike c(1, {}, "c");
  TreeLike a(2, {b, c}, "a");
  using match_ret = Matcher<TreeLike>::return_type;
  using tm = Matcher<TreeLike>;
  tm m([](auto el) {
    if (el.get_name() == "a") {
      return match_ret{false, tm([](auto el) {
                         return match_ret{el.get_name() == "c", boost::none};
                       })};
    }
    return match_ret{false, boost::none};
  });
  auto res = match(a, m);
  for (auto el : res) {
    std::cout << '[' << el.id() << ',' << el.get_name() << ']' << std::endl;
  }
}
