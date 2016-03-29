#include "css.hpp"

#include <iostream>
#include <vector>
#include <string>

struct TreeLike {
  int counter;
  std::vector<TreeLike> children_mem;
  std::string name;
  using iterator = std::vector<TreeLike>::iterator;
  TreeLike(int count, std::vector<TreeLike> children_arg, std::string name_arg)
      : counter(count), children_mem(children_arg), name(name_arg)
  {
  }
  std::string id() const
  {
    return std::to_string(counter);
  }
  iterator begin()
  {
    return children_mem.begin();
  }
  iterator end()
  {
    return children_mem.end();
  }
  std::string get_name() const
  {
    return name;
  }
};

template <typename Vect>
std::string PrintResults(Vect v)
{
  std::string s;
  for (auto el : v) {
    s += std::string("[") + el.id() + std::string(",") + el.get_name() + "]\n";
  }
  return s + "---\n";
}

int main()
{
  using selectree::match::Matcher;
  using selectree::match::match;
  TreeLike d(3, {}, "d");
  TreeLike b(0, {d}, "b");
  TreeLike c(1, {}, "c");
  TreeLike a(2, {b, c}, "a");
  using match_ret = Matcher<TreeLike>::return_type;
  using tm = Matcher<TreeLike>;
  tm m([](auto el) {
    if (el.get_name() == "a") {
      return match_ret(
          true,
          tm([](auto el) { return match_ret(el.get_name() == "c"); }) ||
              !tm([](auto el) { return match_ret(el.get_name() == "b"); }));
    }
    return match_ret();
  });
  auto res = match(a, m);
  std::cout << PrintResults(res);
  tm mAnd = tm([](auto el) { return match_ret(el.get_name() == "b"); }) &&
            tm([](auto el) { return match_ret(el.id() == "0"); });
  auto resAnd = match(a, mAnd);
  std::cout << PrintResults(resAnd);
  tm mOr = tm([](auto el) { return match_ret(el.get_name() == "b"); }) ||
           tm([](auto el) { return match_ret(el.get_name() == "c"); }) ||
           tm([](auto el) { return match_ret(el.get_name() == "a"); });
  auto resOr = match(a, mOr);
  std::cout << PrintResults(resOr);
  tm mNot = !tm([](auto el) { return match_ret(el.get_name() == "b"); }) &&
            !tm([](auto el) { return match_ret(el.id() == "1"); });
  auto resNot = match(a, mNot);
  std::cout << PrintResults(resNot);
  std::cout << "CSS" << std::endl;
  tm mArrow = tm([](auto el) { return match_ret(el.get_name() == "a"); }) >
              tm([](auto el) { return match_ret(el.get_name() == "b"); });
  auto resArrow = match(a, mArrow);
  std::cout << PrintResults(resArrow);
  tm mDesc = tm([](auto el) { return match_ret(el.get_name() == "a"); }) >>
             tm([](auto el) { return match_ret{el.get_name() == "d"}; });
  auto resDesc = match(a, mDesc);
  std::cout << PrintResults(resDesc);
}
