#ifndef ___SELECTREE_MATCH___
#define ___SELECTREE_MATCH___

#include <boost/optional.hpp>
#include <vector>
#include <stdexcept>
#include <unordered_set>
#include <stack>

namespace selectree
{
namespace match
{
template <typename T>
class Iterator;

template <typename T>
struct Matcher {
  using maybe_match = boost::optional<Matcher<T>>;
  struct return_type {
    bool didCompleteMatch;
    maybe_match newMatcher;
    maybe_match sameStageMatcher;
    return_type(bool b = false,
                maybe_match nmatch  = boost::none,
                maybe_match ssmatch = boost::none)
        : didCompleteMatch(b), newMatcher(nmatch), sameStageMatcher(ssmatch)
    {
    }
  };
  using internal_fun_type = std::function<return_type(T &)>;

protected:
  internal_fun_type internal_fun;

  static maybe_match combineByOr(maybe_match, maybe_match);
  static maybe_match combineByAnd(maybe_match, maybe_match);

  friend class Iterator<T>;
  static maybe_match recurse_combine_matchers(Matcher<T>, maybe_match);

public:
  /* TODO: make this quit faster (don't search the whole tree maybe) when a
   * matcher references root */
  Matcher(const internal_fun_type & f) : internal_fun(f)
  {
  }

  /* invoke the lambda that started all this */
  inline return_type operator()(T & arg) const
  {
    return internal_fun(arg);
  }

  /* algebraic operators */
  Matcher<T> operator||(const Matcher<T> &) const;
  Matcher<T> operator&&(const Matcher<T> &) const;
  Matcher<T> operator!() const;

  /*** css combinators ***/
  /* immediate descendant */
  Matcher<T> operator>(const Matcher<T> &) const;
  /* descendant */
  Matcher<T> operator>>(const Matcher<T> &) const;
  /* immediate sibling */
  Matcher<T> operator+(const Matcher<T> &) const;
  /* sibling (corresponding to CSS's ~ operator) */
  Matcher<T> operator^(const Matcher<T> &) const;


  /* match this at current level or any subtree below */
  Matcher<T> infinite() const;
  /* match this at current sibling or any sibling further */
  Matcher<T> infiniteSibling() const;
};

template <typename T>
struct MatchAndNode {
  Matcher<T> match;
  T & parent;
  typename T::iterator curChild;
  typename T::iterator curEnd;
  MatchAndNode(Matcher<T> matcher, T & parent_arg)
      : match(matcher), parent(parent_arg), curChild(std::begin(parent)),
        curEnd(std::end(parent))
  {
  }
};

struct match_iteration_error : public std::runtime_error {
  match_iteration_error(const std::string & s) : std::runtime_error(s)
  {
  }
};

template <typename T>
class Iterator : std::iterator<std::forward_iterator_tag, T>
{
  std::unordered_set<std::string> ids_seen;
  boost::optional<T &> cur_result;
  std::stack<MatchAndNode<T>> cur_branch;

  typename Matcher<T>::maybe_match match_helper(T &, const Matcher<T> &);
  void do_increment();

public:
  Iterator();
  Iterator(T &, const Matcher<T> &);
  Iterator<T> & operator++();
  Iterator<T> operator++(int);
  bool operator==(const Iterator<T> &) const;
  bool operator!=(const Iterator<T> &) const;
  T & operator*() const;
  T * operator->() const;
  bool atEnd() const;
};

template <typename T>
struct Results {
  const Iterator<T> internal;
  Iterator<T> begin() const
  {
    return internal;
  }
  Iterator<T> end() const
  {
    return Iterator<T>();
  }
};

/* note: this strictly evaluates a query; this can block for a while! */
template <typename T>
Results<T> match(T &, const Matcher<T> &);
}
}

#include "match.tpp"

#endif /* ___SELECTREE_MATCH___ */
