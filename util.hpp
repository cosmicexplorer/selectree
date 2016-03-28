#ifndef ___SELECTREE_UTIL___
#define ___SELECTREE_UTIL___

#include <boost/variant.hpp>

namespace selectree
{
namespace util
{
template <typename Vect, typename Func>
Vect map(Vect, Func);

template <typename Vect, typename Func>
Vect filter(Vect, Func);

template <typename Vect, typename T, typename Func>
Vect reduce(Vect, T, Func);

template <typename T, typename... Args>
struct variant_overload_set : public boost::static_visitor<T>, Args... {
  const overload_set<Args...> over_set;
  variant_overload_set(Args...);
  template <typename... VisitorArgs>
  inline T operator()(VisitorArgs...);
};

/* use like:
   boost::variant<int, std::string> var(3);
   auto overloaded_visitor = variant_overload<int>(
     [](int i){ return i; },
     [](std::string s){ return s.size() });
   can have polymorphic lambda as well, but only one unfortunately! */
/* T must be given explicitly! */
template <typename T, typename... Args>
inline variant_overload_set<T, Args...> variant_overload(Args &&...);
}
}

#include "util.tpp"

#endif /* ___SELECTREE_UTIL___ */
