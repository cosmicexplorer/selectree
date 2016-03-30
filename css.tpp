#include <cctype>
#include <regex>

namespace selectree
{
namespace css
{
template <typename T>
match::Matcher<T> generate_matcher(std::string input)
{
  const std::regex ident("^[-]?[_a-zA-Z][_a-zA-Z0-9-]*");
  const std::regex name("^[_a-zA-Z0-9-]+");
  match::Matcher<T>::maybe_match cur_match(boost::none);
  for (auto cur = std::begin(input), end = std::end(input); cur != end; ++cur) {
    if (isspace(*cur)) {
      continue;
    }
    if (!cur_match) {
      auto res  = do_simple_selection<T>(cur, end);
      cur       = res.get<0>();
      cur_match = res.get<1>();
      hit_comb  = true;
    } else {
      do_combination(cur);
    }
  }
  return *cur_match;
}

template <typename T, typename Iterator>
std::tuple<Iterator, match::Matcher<T>>
    do_simple_selection(Iterator cur,
                        Iterator end,
                        const std::regex & ident,
                        const std::regex & name)
{
  using matcher = match::Matcher<T>;
  using rt = matcher::return_type;
  matcher::maybe_match match(boost::none);
  for (!isspace(*cur) && cur != end; ++cur) {
    switch (*cur) {
    case '*':
      if (match) {
        throw parse_error("cannot have multiple type tags (used '*') in single "
                          "simple selector");
      }
      match = matcher([](auto el) { return rt(true); });
      break;
    case '#':
      ++cur;
      auto res = get_next_token(cur, end, name);
      if (res.get<0>() == end) {
        throw parse_error("unrecognized character detected in '#' selector");
      }
      auto tok = res.get<1>();
      match = matcher::combineByOr(match, matcher([=](auto el) {
                                     return rt(el.attribute("id") == tok);
                                   }));
      cur = res.get<0>();
      break;
    case '.':
      ++cur;
      auto res = get_next_token(cur, end, ident);
      if (res.get<0>() == end) {
        throw parse_error("unrecognized character detected in '.' selector");
      }
      auto tok = res.get<1>();
      match = matcher::combineByOr(
          match, matcher([=](auto el) {
              auto s = el.attribute("class");
              auto it = s.find(tok);
              return rt(it == s.begin() or ); }));
      cur = res.get<0>();
      break;
    case '[':
      break;
    case ':':
      break;
    default:
      auto res = get_next_token(cur, end, ident);
      if (res.get<0>() == end) {
        throw parse_error(
            "unrecognized character detected in simple selection for tag type");
      } else if (match) {
        throw parse_error(
            std::string("cannot have multiple type tags (used '") +
            res.get<1>() + "') in single simple selector")
      }
      auto tok = res.get<1>();
      match = matcher([=](auto el) { return rt(el.name() == tok); });
      cur = res.get<0>();
      break;
    }
  }
  return *match;
}

template <typename Iterator>
std::tuple<Iterator, std::string>
    get_next_token(Iterator st, Iterator end, const std::regex & r)
{
  std::smatch matches;
  return std::regex_search(st, end, matches, r)
             ? std::make_tuple(st + matches.length(), matches.str())
             : std::make_tuple(end, "");
}
}
}
