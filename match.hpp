#ifndef ___SELECTREE_MATCH___
#define ___SELECTREE_MATCH___

#include <tuple>
#include <boost/optional.hpp>
#include <functional>
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
    boost::optional<Matcher<T>> newMatcher;
    bool didCompleteMatch;
  };
  using internal_fun_type = std::function<return_type(T)>;
  bool fromRoot;

  Matcher(internal_fun_type, bool = false)
      : internal_fun(f), fromRoot(isFromRoot)
  {
  }
  return_type operator()(T arg)
  {
    return internal_fun(arg);
  }

private:
  internal_fun_type internal_fun;
};

struct match_iteration_error : public std::runtime_error {
  match_iteration_error(const std::string & s) : std::runtime_error(s)
  {
  }
};

template <typename T>
using FunctionsVector = std::vector<Matcher<T>>;

/* implements depth-first lazy search */
template <typename T>
class Iterator : std::iterator<std::input_iterator_tag, T>
{
  T root;
  T cur_result;

  const FunctionsVector orig_matchers;
  FunctionsVector::iterator cur_orig_matcher;
  const FunctionsVector new_matchers;
  FunctionsVector::iterator cur_new_matcher;

  Iterator<T> cur_iterated_results;
  /* a set of std::string and not of T so that we don't keep them in memory
   * forever */
  std::unordered_set<std::string> & ids_seen;

  static FunctionsVector getMatchersForNextStage(FunctionsVector);
  inline bool insertIfUnique(const T &);
  inline bool incrementIteratorUntilResult() const;

public:
  Iterator();
  Iterator(T, FunctionsVector<T>, const Matcher<T> &,
           std::unordered_set<std::string> &);
  inline bool atEnd() const;
  Iterator<T> & operator++();
  inline Iterator<T> operator++(int);
  inline bool operator==(const Iterator<T> &) const;
  inline bool operator!=(const Iterator<T> &) const;
  inline T operator*() const;
};

/* adapter class for range-based for loop */
template <typename T>
class Results
{
  Iterator<T> internal;

public:
  Results(const Iterator<T> & it) : internal(it)
  {
  }
  Iterator<T> begin()
  {
    return internal;
  }
  Iterator<T> end()
  {
    return Iterator<T>();
  }
};
}
}

#include "match.tpp"

#endif /* ___SELECTREE_MATCH___ */
