#include <algorithm>

namespace selectree
{
namespace util
{
template <typename Vect, typename Func>
Vect map(Vect v, Func f)
{
  std::transform(v.begin(), v.end(), v.begin(), f);
  return v;
}

template <typename Vect, typename Func>
Vect filter(Vect v, Func f)
{
  auto ret = std::remove_if(v.begin(), v.end(), f);
  v.erase(ret, std::end(v));
  return v;
}

template <typename Vect, typename T, typename Func>
Vect reduce(Vect v, T init, Func f)
{
  return std::accumulate(v.begin(), v.end(), init, f);
}

template <typename T, typename... Args>
variant_overload_set<T, Args...>::variant_overload_set(Args... args)
    : Args(args)..., over_set(args...)
{
}

template <typename T, typename... Args>
template <typename... VisitorArgs>
T variant_overload_set<T, Args...>::operator()(VisitorArgs... args)
{
  return static_cast<T>(over_set(args...));
}

template <typename T, typename... Args>
variant_overload_set<T, Args...> variant_overload(Args &&... args)
{
  return variant_overload_set<T, Args...>(args...);
}
}
}
