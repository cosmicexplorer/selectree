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
  using maybe_match = boost::optional<Matcher<T>>;
  struct return_type {
    bool didCompleteMatch;
    maybe_match newMatcher;
  };
  using internal_fun_type = std::function<return_type(T)>;

private:
  internal_fun_type internal_fun;
  bool regenerate;

  Matcher<T> setRegenerate(bool) const;

public:
  /* doRegenerate should be set to false when a matcher references root */
  Matcher(bool doRegenerate, internal_fun_type f)
      : internal_fun(f), regenerate(doRegenerate)
  {
  }
  Matcher(const internal_fun_type & f) : internal_fun(f), regenerate(true)
  {
  }

  /* invoke the lambda that started all this */
  inline return_type operator()(T arg) const
  {
    return internal_fun(arg);
  }

  /* used in match() and friends */
  static maybe_match recurse_combine_matchers(Matcher<T>, maybe_match);

  /* algebraic operators */
  Matcher<T> operator||(const Matcher<T> &) const;
  static maybe_match combineByOr(bool, maybe_match, maybe_match);

  Matcher<T> operator&&(const Matcher<T> &) const;
  static maybe_match combineByAnd(bool, maybe_match, maybe_match);

  /* for complement */
  Matcher<T> operator!() const;
};

template <typename T>
using Results = std::vector<T>;

/* note: this strictly evaluates a query; this can block for a while! */
template <typename T>
Results<T> match(T, const Matcher<T> &);
}
}

#include "match.tpp"

#endif /* ___SELECTREE_MATCH___ */
