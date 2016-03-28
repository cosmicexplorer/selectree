#include <functional>
#include <stack>

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
  return Matcher<T>([&](const T & el) {
    return_type left  = that(el);
    return_type right = rhs(el);
    bool condition    = left.didCompleteMatch or right.didCompleteMatch;
    bool r            = regenerate or rhs.regenerate;
    maybe_match comb  = combineByOr(r, left.newMatcher, right.newMatcher);
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
  return Matcher<T>([&](const T & el) {
    return_type left  = that(el);
    return_type right = rhs(el);
    bool condition    = left.didCompleteMatch and right.didCompleteMatch;
    bool r            = regenerate and rhs.regenerate;
    maybe_match comb  = combineByAnd(r, left.newMatcher, right.newMatcher);
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
  return Matcher<T>([&](auto el) {
    auto res  = (*this)(el);
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
  return nextStage;
}

template <typename T>
Results<T> match(T root, const Matcher<T> & matcher)
{
  /* keep only the ids in a set, NOT the Ts themselves */
  /* TODO: is std::string the best data type for unique ids? */
  std::unordered_set<std::string> ids_seen;
  Results<T> results;
  struct MatchAndNode {
    Matcher<T> match;
    std::vector<T> children;
    typename std::vector<T>::iterator curChild;
    MatchAndNode(Matcher<T> matcher, const std::vector<T> & child_v)
        : match(matcher), children(child_v), curChild(children.begin())
    {
    }
  };
  std::stack<MatchAndNode> cur_branch;
  std::vector<T> children{root};
  cur_branch.emplace(matcher, children);
  while (!cur_branch.empty()) {
    MatchAndNode & cur = cur_branch.top();
    if (cur.curChild == cur.children.end()) {
      cur_branch.pop();
      continue;
    }
    T node = *cur.curChild;
    ++cur.curChild;
    auto curMatcher = cur.match;
    auto res = curMatcher(node);
    if (res.didCompleteMatch and ids_seen.find(node.id()) == ids_seen.end()) {
      ids_seen.insert(node.id());
      results.push_back(node);
    }
    auto nextMatcher =
        Matcher<T>::recurse_combine_matchers(curMatcher, res.newMatcher);
    if (nextMatcher) {
      auto children = node.children();
      auto beg      = children.begin();
      auto end = children.end();
      if (beg != end) {
        cur_branch.emplace(*nextMatcher, children);
      }
    }
  }
  return results;
}
}
}
