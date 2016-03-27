#ifndef ___SELECTREE_UTIL___
#define ___SELECTREE_UTIL___

namespace selectree {
namespace util {
template <typename Vect, typename Func>
Vect map(Vect, Func);

template <typename Vect, typename Func>
Vect filter(Vect, Func);

template <typename Vect, typename T, typename Func>
Vect reduce(Vect, T, Func);
}

#include "util.tpp"

#endif /* ___SELECTREE_UTIL___ */
