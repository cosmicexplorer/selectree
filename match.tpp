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
Iterator<T>::Iterator()
    : ids_seen(), cur_result(boost::none), cur_branch()
{
}

template <typename T>
void Iterator<T>::match_helper(T & node, const Matcher<T> & matcher)
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
    match_helper(node, curMatcher);
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
