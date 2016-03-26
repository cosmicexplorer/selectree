#ifndef ___SELECTREE_SELECTREE___
#define ___SELECTREE_SELECTREE___

#include <string>
#include <queue>
#include <iterator>

namespace selectree
{
/* requires: name -> std::string, children -> iterable<T>,
 * attribute(std::string) -> T, attributeKeys -> iterable<std::string>,
 * value -> std::string */
/* value() is used for 'tag[key="value"]' constructions */
/* universal reference allows us to use references or rvalues and respects
 * constness; if copy ctor deleted, then defaults to T&, for example */
template <typename T>
MatchResults<T &> css(T &, std::string);
template <typename T>
MatchResults<T> css(T, std::string);

template <typename T>
MatchResults<T &> xpath(T &, std::string);
template <typename T>
MatchResults<T> xpath(T, std::string);

template <typename T>
class MatchIterator : std::iterator<std::input_iterator_tag, T>
{
  std::queue<T> cur;

public:
  MatchIterator();
  MatchIterator(const MatchIterator &) = delete;
  MatchIterator & operator++();
  MatchIterator operator++(int);
  bool operator==(const MatchIterator &) const;
  bool operator!=(const MatchIterator &) const;
  T operator*() const;
};

/* adapter class for range-based for loop */
template <typename T>
class MatchResults
{
  MatchIterator<T> internal;

public:
  MatchResults(const MatchIterator<T> &);
  MatchIterator<T> begin();
  MatchIterator<T> end();
};
}

#include "SelecTree.tpp"

#endif /* ___SELECTREE_SELECTREE___ */
