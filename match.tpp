#include <functional>

namespace selectree
{
namespace match
{
template <typename T>
Matcher<T> Matcher<T>::setRegenerate(bool regen) const
{
  Matcher<T> tmp(*this);
  tmp.regenerate = regen;
  return tmp;
}

template <typename T>
Matcher<T> Matcher<T>::operator||(const Matcher<T> & rhs) const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](auto el) {
    return_type left(that(el));
    return_type right(rhs(el));
    bool condition   = left.didCompleteMatch or right.didCompleteMatch;
    bool r           = regenerate or rhs.regenerate;
    maybe_match comb = combineByOr(r, left.newMatcher, right.newMatcher);
    return return_type{condition, comb};
  });
}

template <typename T>
typename Matcher<T>::maybe_match
    Matcher<T>::combineByOr(bool regen,
                            typename Matcher<T>::maybe_match left,
                            typename Matcher<T>::maybe_match right)
{
  if (left and right) {
    return (*left || *right).setRegenerate(regen); /* this is OUR operator|| */
  } else if (left) {
    return left->setRegenerate(regen);
  } else if (right) {
    return right->setRegenerate(regen);
  }
  return boost::none;
}

template <typename T>
Matcher<T> Matcher<T>::operator&&(const Matcher<T> & rhs) const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](auto el) {
    return_type left(that(el));
    return_type right(rhs(el));
    bool condition   = left.didCompleteMatch and right.didCompleteMatch;
    bool r           = regenerate and rhs.regenerate;
    maybe_match comb = combineByAnd(r, left.newMatcher, right.newMatcher);
    return return_type{condition, comb};
  });
}

template <typename T>
typename Matcher<T>::maybe_match
    Matcher<T>::combineByAnd(bool regen,
                             typename Matcher<T>::maybe_match left,
                             typename Matcher<T>::maybe_match right)
{
  if (left and right) {
    return (*left && *right).setRegenerate(regen); /* this is OUR operator&& */
  }
  return boost::none;
}

template <typename T>
Matcher<T> Matcher<T>::operator!() const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](auto el) {
    return_type res(that(el));
    bool cond = !res.didCompleteMatch;
    return_type result;
    if (res.newMatcher) {
      Matcher<T> tmp(!*res.newMatcher);
      tmp.regenerate = regenerate;
      result         = {cond, tmp};
    } else {
      result = {cond, boost::none};
    }
    return result;
  });
}

template <typename T>
typename Matcher<T>::maybe_match Matcher<T>::recurse_combine_matchers(
    Matcher<T> cur, typename Matcher<T>::maybe_match nextStage)
{
  if (cur.regenerate) {
    if (nextStage) {
      return cur || *nextStage;
    }
    return cur;
  }
  if (nextStage) {
    return *nextStage;
  }
  return boost::none;
}

template <typename T>
Results<T> match(T root, const Matcher<T> & origMatcher)
{
  /* keep only the ids in a set, NOT the Ts themselves */
  /* TODO: is std::string the best data type for unique ids? */
  std::unordered_set<std::string> ids_seen;
  Results<T> results;
  match_recurse(root, origMatcher, ids_seen, results);
  return results;
}

/* TODO: make this stack-based so it doesn't stack overflow and so we can
   support lazy creation of results; check out branch stack-based (which
   segfaults) */
template <typename T>
void match_recurse(T & root,
                   const Matcher<T> & matcher,
                   std::unordered_set<std::string> & ids_seen,
                   Results<T> & results)
{
  auto res = matcher(root);
  if (res.didCompleteMatch and ids_seen.find(root.id()) == ids_seen.end()) {
    ids_seen.insert(root.id());
    results.push_back(root);
  }
  auto nextMatcher =
      Matcher<T>::recurse_combine_matchers(matcher, res.newMatcher);
  /* quit this subtree if original is from root and no new matcher given */
  if (nextMatcher) {
    for (auto child : root.children()) {
      match_recurse(child, *nextMatcher, ids_seen, results);
    }
  }
}
}
}
