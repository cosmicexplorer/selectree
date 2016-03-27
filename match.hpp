#ifndef ___SELECTREE_MATCH___
#define ___SELECTREE_MATCH___

#include <boost/optional.hpp>
#include <vector>
#include <stdexcept>
#include <unordered_set>

namespace selectree
{
namespace match
{
template <typename T>
struct Matcher {
  struct return_type {
    bool didCompleteMatch;
    boost::optional<Matcher<T>> newMatcher;
  };
  using internal_fun_type = std::function<return_type(T)>;

  Matcher(internal_fun_type f, bool isFromRoot = false)
      : internal_fun(f), fromRoot(isFromRoot)
  {
  }
  return_type operator()(T arg) const
  {
    return internal_fun(arg);
  }

private:
  internal_fun_type internal_fun;
  const bool fromRoot;
};

struct match_iteration_error : public std::runtime_error {
  match_iteration_error(const std::string & s) : std::runtime_error(s)
  {
  }
};

template <typename T>
using Results = std::vector<T>;

/* note: this strictly evaluates a query; this can block for a while! */
template <typename T>
Results<T> match(T, const Matcher<T> &);

/* match is thread-safe; not these! you shouldn't be using these anyway */
template <typename T>
void do_match(T &,
              const Matcher<T> &,
              const Matcher<T> &,
              std::unordered_set<std::string> &,
              Results<T> &);

template <typename T>
void match_recurse(T &,
                   const Matcher<T> &,
                   boost::optional<Matcher<T>>,
                   std::unordered_set<std::string> &,
                   Results<T> &);
}
}

#include "match.tpp"

#endif /* ___SELECTREE_MATCH___ */
