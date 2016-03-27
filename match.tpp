#include <algorithm>

namespace selectree
{
namespace match
{
template <typename T>
Iterator<T>::getMatchersForNextStage(FunctionsVector v)
{
  return util::filter(v, [](auto el) { return !el.fromRoot });
}

template <typename T>
bool Iterator<T>::insertIfUnique(const T & arg)
{
  if (ids_seen.find(arg.id()) == ids_seen.end()) {
    ids_seen.insert(arg.id());
    cur_results.push(arg);
    return true;
  }
  return false;
}

template <typename T>
bool Iterator<T>::incrementIteratorUntilResult() const
{
  while (!cur_iterated_results.atEnd()) {
    auto cur = *(cur_iterated_results++);
    if (insertIfUnique(cur)) {
      return true;
    }
  }
  return false;
}

template <typename T>
Iterator<T>::Iterator()
    : root(boost::none), cur_result(boost::none), orig_matchers(),
      cur_orig_matcher(), new_matchers(), cur_new_matcher(),
      cur_iterated_results()
{
}

template <typename T>
Iterator<T>::Iterator(T start, FunctionsVector<T> matchFuns,
                      FunctionsVector<T> newMatchers,
                      std::unordered_set<std::string> & have_seen_previously)
    : root(start), cur_result(boost::none), orig_matchers(matchFuns),
      cur_orig_matcher(orig_matchers.begin()), new_matchers(newMatchers),
      cur_new_matcher(new_matchers.begin()), cur_iterated_results(),
      ids_seen(have_seen_previously)
{
}

template <typename T>
bool Iterator<T>::atEnd() const
{
  return cur_results.empty() and cur_iterated_results.atEnd() and
         cur_children.empty();
}

template <typename T>
Iterator<T> & Iterator<T>::operator++()
{
  if (atEnd()) {
    throw match_iteration_error("iterator is at end of match results!");
  }
  if (!cur_results.empty()) {
    cur_results.pop();
    return *this;
  }
  if (incrementIteratorUntilResult()) {
    return *this;
  }
  /* this is the possibly long-blocking part */
  if (!cur_children.empty()) {
    while (cur_results.empty() and !cur_children.empty() and
           cur_iterated_results.atEnd()) {
      T curChild = cur_children.front();
      cur_children.pop();
      for (auto & matcher : matchers) {
        auto res = matcher(curChild);
        /* add result to cur_results */
        if (res.didCompleteMatch) {
          insertIfUnique(curChild);
        }
        FunctionsVector newMatchers(getMatchersForNextStage(matchers));
        /* see if any intermediate results happen */
        if (res.newMatcher) {
          newMatchers.push_back(*res);
        }
        if (newMatchers.size() > 0) {
          cur_iterated_results = Iterator(curChild, newMatchers);
        }
      }
      if (incrementIteratorUntilResult()) {
        return *this;
      }
    }
  }
  if (incrementIteratorUntilResult()) {
    return *this;
  }
  return *this;
}

template <typename T>
Iterator<T> Iterator<T>::operator++(int)
{
  Iterator copy(*this);
  ++*this;
  return copy;
}

template <typename T>
bool Iterator<T>::operator==(const Iterator<T> & rhs) const
{
  if (atEnd()) {
    return rhs.atEnd();
  }
  if (rhs.atEnd()) { /* this is NOT at end */
    return false;
  }
  /* neither are at end, this means we can safely deref */
  return (*(*this)).id() == (*rhs).id();
}

template <typename T>
bool Iterator<T>::operator!=(const Iterator<T> & rhs) const
{
  return !(*this == rhs);
}

template <typename T>
T Iterator<T>::operator*() const
{
  return cur_results.front();
}
}
}
