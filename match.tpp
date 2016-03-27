namespace selectree
{
namespace match
{
template <typename T>
Results<T> match(T root, const Matcher<T> & origMatcher)
{
  /* keep only the ids in a set, NOT the Ts themselves */
  /* TODO: is std::string the best data type for unique ids? */
  std::unordered_set<std::string> ids_seen;
  Results<T> results;
  boost::optional<Matcher<T>> temp(boost::none);
  /* TODO: add all matchers that reference root to newMatchers here */
  match_recurse(root, origMatcher, temp, ids_seen, results);
  return results;
}

template <typename T>
void do_match(T & root,
              const Matcher<T> & matcher,
              const Matcher<T> & origMatcher,
              std::unordered_set<std::string> & ids_seen,
              Results<T> & results)
{
  auto res = matcher(root);
  if (res.didCompleteMatch and ids_seen.find(root.id()) == ids_seen.end()) {
    ids_seen.insert(root.id());
    results.push_back(root);
  }
  for (auto child : root.children()) {
    match_recurse(child, origMatcher, res.newMatcher, ids_seen, results);
  }
}

template <typename T>
void match_recurse(T & root,
                   const Matcher<T> & origMatcher,
                   boost::optional<Matcher<T>> tempMatcher,
                   std::unordered_set<std::string> & ids_seen,
                   Results<T> & results)
{
  do_match(root, origMatcher, origMatcher, ids_seen, results);
  if (tempMatcher) {
    do_match(root, *tempMatcher, origMatcher, ids_seen, results);
  }
}
}
}
