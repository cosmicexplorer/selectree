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

template <typename Vect>
void CheckSame(Vect v, std::vector<TreeLike> v2)
{

  auto i = std::begin(v);
  auto j = std::begin(v2);
  for (; i != std::end(v) && j != std::end(v2); ++i, ++j) {
    if (i->id() != j->id()) {
      std::cerr << "failed:\n" << PrintResults(v) << "is not equal to\n"
                << PrintResults(v2);
      return;
    }
  }
  if (i != std::end(v) || j != std::end(v2)) {
    std::cerr << "failed:\n" << PrintResults(v) << "is not equal to\n"
              << PrintResults(v2);
  } else {
    std::cerr << "succeeded" << std::endl;
  }
}

int main()
{
  using selectree::match::Matcher;
  using selectree::match::match;
  TreeLike e(4, {}, "e");
  TreeLike d(3, {}, "d");
  TreeLike b(0, {d}, "b");
  TreeLike c(1, {}, "c");
  TreeLike a(2, {b, c, e}, "a");
  using match_ret = Matcher<TreeLike>::return_type;
  using tm = Matcher<TreeLike>;
  tm m1([](auto el) {
    if (el.get_name() == "a") {
      return match_ret(
          true, !tm([](auto el) { return match_ret(el.get_name() == "b"); }));
    }
    return match_ret();
  });
  auto res1 = match(a, m1);
  CheckSame(res1, {a, c, e});
  tm m([](auto el) {
    if (el.get_name() == "a") {
      return match_ret(true, (!tm([](auto el) {
                               return match_ret(el.get_name() == "b");
                             })).infinite());
    }
    return match_ret();
  });
  auto res = match(a, m);
  CheckSame(res, {a, d, c, e});
  tm mAnd = tm([](auto el) { return match_ret(el.get_name() == "b"); }) &&
            tm([](auto el) { return match_ret(el.id() == "0"); });
  auto resAnd = match(a, mAnd);
  CheckSame(resAnd, {b});
  tm mOr = tm([](auto el) { return match_ret(el.get_name() == "b"); }) ||
           tm([](auto el) { return match_ret(el.get_name() == "c"); }) ||
           tm([](auto el) { return match_ret(el.get_name() == "a"); });
  auto resOr = match(a, mOr);
  CheckSame(resOr, {a, b, c});
  tm mNot = !tm([](auto el) { return match_ret(el.get_name() == "b"); }) &&
            !tm([](auto el) { return match_ret(el.id() == "1"); });
  auto resNot = match(a, mNot);
  CheckSame(resNot, {a, d, e});
  std::cerr << "CSS" << std::endl;
  tm mArrow = tm([](auto el) { return match_ret(el.get_name() == "a"); }) >
              tm([](auto el) { return match_ret(el.get_name() == "b"); });
  auto resArrow = match(a, mArrow);
  CheckSame(resArrow, {b});
  tm mArrow2 = tm([](auto el) { return match_ret(el.get_name() == "a"); }) >
               tm([](auto el) { return match_ret(el.get_name() == "d"); });
  auto resArrow2 = match(a, mArrow2);
  CheckSame(resArrow2, {});
  tm mArrow3 = tm([](auto el) { return match_ret(el.get_name() == "b"); }) >
               tm([](auto el) { return match_ret(el.get_name() == "e"); });
  auto resArrow3 = match(a, mArrow3);
  CheckSame(resArrow3, {});
  tm mDesc = tm([](auto el) { return match_ret(el.get_name() == "a"); }) >>
             tm([](auto el) { return match_ret{el.get_name() == "d"}; });
  auto resDesc = match(a, mDesc);
  CheckSame(resDesc, {d});
  tm mDesc2 = tm([](auto el) { return match_ret(el.get_name() == "a"); }) >>
              tm([](auto el) { return match_ret{el.get_name() == "b"}; });
  auto resDesc2 = match(a, mDesc2);
  CheckSame(resDesc2, {b});
  tm mNeighb = tm([](auto el) { return match_ret(el.get_name() == "b"); }) +
               tm([](auto el) { return match_ret(el.get_name() == "c"); });
  auto resNeighb = match(a, mNeighb);
  CheckSame(resNeighb, {c});
  tm mNeighb2 = tm([](auto el) { return match_ret(el.get_name() == "b"); }) +
                tm([](auto el) { return match_ret(el.get_name() == "e"); });
  auto resNeighb2 = match(a, mNeighb2);
  CheckSame(resNeighb2, {});
  tm mSib = tm([](auto el) { return match_ret(el.get_name() == "b"); }) ^
            tm([](auto el) { return match_ret(el.get_name() == "c"); });
  auto resSib = match(a, mSib);
  CheckSame(resSib, {c});
  tm mSib2 = tm([](auto el) { return match_ret(el.get_name() == "b"); }) ^
             tm([](auto el) { return match_ret(el.get_name() == "e"); });
  auto resSib2 = match(a, mSib2);
  CheckSame(resSib2, {e});
}
