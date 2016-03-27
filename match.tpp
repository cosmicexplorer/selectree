namespace selectree
{
namespace match
{
template <typename T>
Matcher<T>::Matcher(const Matcher<T>::internal_fun_type & f)
    : internal_fun(f)
{
}

template <typename T>
Matcher<T>::operator()(T arg)
{
  return internal_fun(arg);
}

template <typename T>
Iterator<T>::Iterator(T root, FunctionsVector<T> matchFuns)
    : cur_children(root.children()), cur_results(), matchers(matchFuns)
{
}

template <typename T>
bool Iterator<T>::atEnd()
{
  return cur_results.empty() and cur_children.empty() and
         (!cur_iterated_results or cur_iterated_results.atEnd());
}

template <typename T>
Iterator<T> & Iterator<T>::operator++()
{
  /* TODO: if we dedup the results here, we can use .id() to check equality of
     iterators */
  if (!cur_results.empty()) {
    cur_results.pop();
  }
  /* this is the possibly long-blocking part */
  if (!cur_children.empty()) {
    while (cur_results.empty() and !cur_children.empty() and
           (!cur_iterated_results or cur_iterated_results.atEnd())) {
      T curChild = cur_children.front();
      cur_children.pop();
      for (auto & matcher : matchers) {
        auto res = matcher(curChild);
        /* add result to cur_results */
        if (res.didCompleteMatch) {
          cur_results.push_back(curChild);
        }
        /* see if any intermediate results happen */
        if (res.newMatch) {
          FunctionsVector newMatchers(matchers);
          newMatchers.push_back(*res);
          cur_iterated_results = Iterator(curChild, newMatchers);
        }
      }
    }
  }
  if (cur_iterated_results and !cur_iterated_results.atEnd()) {
    return *(cur_iterated_results++);
  }
  cur_iterated_results = boost::none;
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
  return atEnd() and rhs.atEnd();
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
