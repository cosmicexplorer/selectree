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
Results<T> match(T root, const Matcher<T> & matcher)
{
  /* keep only the ids in a set, NOT the Ts themselves */
  /* TODO: is std::string the best data type for unique ids? */
  std::unordered_set<std::string> ids_seen;
  Results<T> results;
  std::stack<MatchAndNode<T>> cur_branch;
  auto res_root = matcher(root);
  match_helper(root, matcher, ids_seen, results, cur_branch);
  while (!cur_branch.empty()) {
    MatchAndNode<T> & cur = cur_branch.top();
    if (cur.curChild == cur.curEnd) {
      cur_branch.pop();
      continue;
    }
    T node = *cur.curChild;
    ++cur.curChild;
    auto curMatcher = cur.match;
    match_helper(node, curMatcher, ids_seen, results, cur_branch);
  }
  return results;
}

template <typename T>
void match_helper(T cur,
                  const Matcher<T> & matcher,
                  std::unordered_set<std::string> ids_seen,
                  Results<T> & results,
                  std::stack<MatchAndNode<T>> & cur_branch)
{
  auto res = matcher(cur);
  if (res.didCompleteMatch and ids_seen.find(cur.id()) == ids_seen.end()) {
    ids_seen.insert(cur.id());
    results.push_back(cur);
  }
  auto nextMatcher =
      Matcher<T>::recurse_combine_matchers(matcher, res.newMatcher);
  if (nextMatcher) {
    cur_branch.emplace(*nextMatcher, cur);
  }
}
}
}
