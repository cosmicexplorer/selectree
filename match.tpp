namespace selectree
{
namespace match
{
template <typename T>
Matcher<T> Matcher<T>::operator||(const Matcher<T> & rhs) const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type left(that(el));
    return_type right(rhs(el));
    bool condition   = left.didCompleteMatch or right.didCompleteMatch;
    maybe_match comb = combineByOr(left.newMatcher, right.newMatcher);
    maybe_match same_comb =
        combineByOr(left.sameStageMatcher, right.sameStageMatcher);
    return return_type(condition, comb);
  });
}

template <typename T>
typename Matcher<T>::maybe_match
    Matcher<T>::combineByOr(typename Matcher<T>::maybe_match left,
                            typename Matcher<T>::maybe_match right)
{
  if (left and right) {
    return *left || *right; /* this is OUR operator|| */
  } else if (left) {
    return left;
  } else if (right) {
    return right;
  }
  return boost::none;
}

template <typename T>
Matcher<T> Matcher<T>::operator&&(const Matcher<T> & rhs) const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type left(that(el));
    return_type right(rhs(el));
    bool condition   = left.didCompleteMatch and right.didCompleteMatch;
    maybe_match comb = combineByAnd(left.newMatcher, right.newMatcher);
    maybe_match same_comb =
        combineByAnd(left.sameStageMatcher, left.sameStageMatcher);
    return return_type(condition, comb, same_comb);
  });
}

template <typename T>
typename Matcher<T>::maybe_match
    Matcher<T>::combineByAnd(typename Matcher<T>::maybe_match left,
                             typename Matcher<T>::maybe_match right)
{
  if (left and right) {
    return *left && *right; /* this is OUR operator&& */
  }
  return boost::none;
}

template <typename T>
Matcher<T> Matcher<T>::operator!() const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type res(that(el));
    bool cond = !res.didCompleteMatch;
    return_type result;
    if (res.newMatcher) {
      Matcher<T> newm(!*res.newMatcher);
      if (res.sameStageMatcher) {
        return return_type(cond, newm, !*res.sameStageMatcher);
      }
      return return_type(cond, newm);
    }
    if (res.sameStageMatcher) {
      Matcher<T> sm(!*res.sameStageMatcher);
      return return_type(cond, boost::none, sm);
    }
    return return_type(cond);
  });
}

template <typename T>
Matcher<T> Matcher<T>::operator>(const Matcher<T> & rhs) const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type left(that(el));
    bool cond = left.didCompleteMatch;
    maybe_match next(cond ? maybe_match(rhs) : boost::none);
    maybe_match child(
        left.newMatcher ? combineByOr((*left.newMatcher > rhs), next) : next);
    maybe_match same_stage(
        left.sameStageMatcher
            ? combineByOr((*left.sameStageMatcher > rhs), next)
            : next);
    return return_type(false, child, same_stage);
  });
}

template <typename T>
Matcher<T> Matcher<T>::operator>>(const Matcher<T> & rhs) const
{
  return (*this) > rhs.infinite();
}

template <typename T>
Matcher<T> Matcher<T>::operator+(const Matcher<T> & rhs) const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type left(that(el));
    bool cond = left.didCompleteMatch;
    maybe_match next(cond ? maybe_match(rhs) : boost::none);
    maybe_match child(
        left.newMatcher ? combineByOr((*left.newMatcher + rhs), next) : next);
    maybe_match same_stage(
        left.sameStageMatcher
            ? combineByOr((*left.sameStageMatcher + rhs), next)
            : next);
    return return_type(cond, child, same_stage);
  });
}

template <typename T>
Matcher<T> Matcher<T>::operator^(const Matcher<T> & rhs) const
{
  return ((*this) + rhs).infiniteSibling();
}

template <typename T>
Matcher<T> Matcher<T>::infinite() const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type res(that(el));
    return return_type(res.didCompleteMatch, combineByOr(that, res.newMatcher),
                       res.sameStageMatcher);
  });
}

template <typename T>
Matcher<T> Matcher<T>::infiniteSibling() const
{
  const Matcher<T> & that = *this;
  return Matcher<T>([=](T & el) {
    return_type res(that(el));
    return return_type(res.didCompleteMatch, res.newMatcher,
                       combineByOr(res.sameStageMatcher, res));
  });
}

template <typename T>
typename Matcher<T>::maybe_match Matcher<T>::recurse_combine_matchers(
    Matcher<T> cur, typename Matcher<T>::maybe_match nextStage)
{
  if (nextStage) {
    return cur || *nextStage;
  }
  return cur;
}

template <typename T>
Iterator<T>::Iterator()
    : ids_seen(), cur_result(boost::none), cur_branch()
{
}

template <typename T>
typename Matcher<T>::maybe_match
    Iterator<T>::match_helper(T & node, const Matcher<T> & matcher)
{
  auto res = matcher(node);
  auto id = node.id();
  if (res.didCompleteMatch and ids_seen.find(id) == ids_seen.end()) {
    ids_seen.insert(id);
    cur_result = node;
  }
  auto nextMatcher =
      Matcher<T>::recurse_combine_matchers(matcher, res.newMatcher);
  if (nextMatcher) {
    cur_branch.emplace(*nextMatcher, node);
  }
  return res.sameStageMatcher;
}

template <typename T>
void Iterator<T>::do_increment()
{
  while (!cur_branch.empty() && !cur_result) {
    MatchAndNode<T> & cur = cur_branch.top();
    if (cur.curChild == cur.curEnd) {
      cur_branch.pop();
      continue;
    }
    T & node = *cur.curChild;
    ++cur.curChild;
    Matcher<T> & curMatcher = cur.match;
    auto sameStageMatcher = match_helper(node, curMatcher);
    if (sameStageMatcher) {
      curMatcher = *sameStageMatcher;
    }
  }
}

template <typename T>
Iterator<T>::Iterator(T & root, const Matcher<T> & matcher)
    : ids_seen(), cur_result(boost::none), cur_branch()
{
  match_helper(root, matcher);
  do_increment();
}

template <typename T>
Iterator<T> & Iterator<T>::operator++()
{
  if (atEnd()) {
    throw match_iteration_error("incrementing iterator at end of matches!");
  }
  cur_result = boost::none;
  do_increment();
  return *this;
}

template <typename T>
Iterator<T> Iterator<T>::operator++(int)
{
  Iterator<T> tmp(*this);
  ++(*this);
  return tmp;
}

template <typename T>
bool Iterator<T>::operator==(const Iterator<T> & rhs) const
{
  return (atEnd() and rhs.atEnd()) or ((&cur_result) == (&rhs.cur_result));
}

template <typename T>
bool Iterator<T>::operator!=(const Iterator<T> & rhs) const
{
  return !((*this) == rhs);
}

template <typename T>
T & Iterator<T>::operator*() const
{
  if (cur_result) {
    return *cur_result;
  }
  throw match_iteration_error("dereferencing iterator at end of matches!");
}

template <typename T>
T * Iterator<T>::operator->() const
{
  if (cur_result) {
    return addressof(operator*());
  }
  throw match_iteration_error("dereferencing iterator at end of matches!");
}

template <typename T>
bool Iterator<T>::atEnd() const
{
  return !cur_result;
}

template <typename T>
Results<T> match(T & root, const Matcher<T> & matcher)
{
  return Results<T>{Iterator<T>(root, matcher)};
}
}
}
