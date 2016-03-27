#ifndef ___SELECTREE_MATCH___
#define ___SELECTREE_MATCH___

#include <tuple>
#include <boost/optional.hpp>
#include <functional>
#include <vector>

namespace selectree
{
namespace match
{
template <typename T>
struct Matcher
{
  struct return_type {
    boost::optional<const Matcher<T> &> newMatch;
    bool didCompleteMatch;
  };
  using internal_fun_type = std::function<return_type(T)>;
  Matcher(const internal_fun_type &);
  return_type operator()(T);
private:
  internal_fun_type internal_fun;
};

template <typename T>
using FunctionsVector = std::vector<const Matcher<T> &>;

/* implements depth-first lazy search */
template <typename T>
class Iterator : std::iterator<std::input_iterator_tag, T>
{
  /* pop off as you collect results */
  std::queue<T> cur_children;
  /* pop on as you collect results from children, pop off during increment */
  std::queue<T> cur_results;
  const FunctionsVector matchers;
  boost::optional<Iterator> cur_iterated_results;

public:
  Iterator(T, FunctionsVector<T>);
  inline bool atEnd();
  Iterator & operator++();
  inline Iterator operator++(int);
  /* these both only work for comparison against the end()! */
  inline bool operator==(const Iterator &) const;
  inline bool operator!=(const Iterator &) const;
  inline T operator*() const;
};

/* adapter class for range-based for loop */
template <typename T>
class Results
{
  Iterator<T> internal;

public:
  Results(const Iterator<T> &);
  Iterator<T> begin();
  Iterator<T> end();
};
}
}

#include "match.tpp"

#endif /* ___SELECTREE_MATCH___ */
