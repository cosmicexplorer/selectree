#ifndef ___SELECTREE_CSS___
#define ___SELECTREE_CSS___

#include "match.hpp"

#include <boost/spirit/include/phoenix_stl.hpp>

namespace selectree
{
namespace css
{
/* FLEX LEXER
%option case-insensitive

ident     [-]?{nmstart}{nmchar}*
name      {nmchar}+
nmstart   [_a-z]|{nonascii}|{escape}
nonascii  [^\0-\177]
unicode   \\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?
escape    {unicode}|\\[^\n\r\f0-9a-f]
nmchar    [_a-z0-9-]|{nonascii}|{escape}
num       [0-9]+|[0-9]*\.[0-9]+
string    {string1}|{string2}
string1   \"([^\n\r\f\\"]|\\{nl}|{nonascii}|{escape})*\"
string2   \'([^\n\r\f\\']|\\{nl}|{nonascii}|{escape})*\'
invalid   {invalid1}|{invalid2}
invalid1  \"([^\n\r\f\\"]|\\{nl}|{nonascii}|{escape})*
invalid2  \'([^\n\r\f\\']|\\{nl}|{nonascii}|{escape})*
nl        \n|\r\n|\r|\f
w         [ \t\r\n\f]*

D         d|\\0{0,4}(44|64)(\r\n|[ \t\r\n\f])?
E         e|\\0{0,4}(45|65)(\r\n|[ \t\r\n\f])?
N         n|\\0{0,4}(4e|6e)(\r\n|[ \t\r\n\f])?|\\n
O         o|\\0{0,4}(4f|6f)(\r\n|[ \t\r\n\f])?|\\o
T         t|\\0{0,4}(54|74)(\r\n|[ \t\r\n\f])?|\\t
V         v|\\0{0,4}(58|78)(\r\n|[ \t\r\n\f])?|\\v

%%

[ \t\r\n\f]+     return S;

"~="             return INCLUDES;
"|="             return DASHMATCH;
"^="             return PREFIXMATCH;
"$="             return SUFFIXMATCH;
"*="             return SUBSTRINGMATCH;
{ident}          return IDENT;
{string}         return STRING;
{ident}"("       return FUNCTION;
{num}            return NUMBER;
"#"{name}        return HASH;
{w}"+"           return PLUS;
{w}">"           return GREATER;
{w}","           return COMMA;
{w}"~"           return TILDE;
":"{N}{O}{T}"("  return NOT;
@{ident}         return ATKEYWORD;
{invalid}        return INVALID;
{num}%           return PERCENTAGE;
{num}{ident}     return DIMENSION;
"<!--"           return CDO;
"-->"            return CDC;

\/\*[^*]*\*+([^/*][^*]*\*+)*\/

.                return *yytext;
*/
/* BISON GRAMMAR
selectors_group
  : selector [ COMMA S* selector ]*
  ;

selector
  : simple_selector_sequence [ combinator simple_selector_sequence ]*
  ;

combinator
  : PLUS S* | GREATER S* | TILDE S* | S+
  ;

simple_selector_sequence
  : [ type_selector | universal ]
    [ HASH | class | attrib | pseudo | negation ]*
  | [ HASH | class | attrib | pseudo | negation ]+
  ;

type_selector
  : [ namespace_prefix ]? element_name
  ;

namespace_prefix
  : [ IDENT | '*' ]? '|'
  ;

element_name
  : IDENT
  ;

universal
  : [ namespace_prefix ]? '*'
  ;

class
  : '.' IDENT
  ;

attrib
  : '[' S* [ namespace_prefix ]? IDENT S*
        [ [ PREFIXMATCH |
            SUFFIXMATCH |
            SUBSTRINGMATCH |
            '=' |
            INCLUDES |
            DASHMATCH ] S* [ IDENT | STRING ] S*
        ]? ']'
  ;

pseudo
  : ':' ':'? [ IDENT | functional_pseudo ]
  ;

functional_pseudo
  : FUNCTION S* expression ')'
  ;

expression
  : [ [ PLUS | '-' | DIMENSION | NUMBER | STRING | IDENT ] S* ]+
  ;

negation
  : NOT S* negation_arg S* ')'
  ;

negation_arg
  : type_selector | universal | HASH | class | attrib | pseudo
  ;
*/
template <typename T>
match::Matcher<T> generate_matcher(std::string);

namespace tokens
{
struct ident {
  std::string str;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(ident, (std::string, str))
/* clang-format on */

struct name {
  std::string str;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(name, str)
/* clang-format on */

struct hash {
  std::string str;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(hash, str)
/* clang-format on */

struct string_tok {
  std::string str;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(string_tok, str)
/* clang-format on */

struct attrib_match_type {
  std::string str;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(attrib_match_type, str)
/* clang-format on */

struct combinator {
  std::string comb;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(combinator, str)
/* clang-format on */
}

namespace nonterminals
{
template <typename T>
struct selector {
  /* TODO: this is the start symbol! */
  virtual match::Matcher<T> makeMatcher() = 0;
};

template <typename T>
struct simple_selector : public selector<T> {
  virtual match::Matcher<T> makeMatcher() = 0;
};

template <typename T>
struct selectors_group : public selector<T> {
  std::vector<std::unique_ptr<simple_selector_sequence<T>>> selectors;
  virtual match::Matcher<T> makeMatcher();
};

template <typename T>
struct comb_and_sel {
  tokens::combinator comb;
  std::unique_ptr<simple_selector<T>> sel;
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (comb_and_sel), comb, sel)
/* clang-format on */

template <typename T>
struct simple_selector_sequence : public selector<T> {
  std::unique_ptr<simple_selector<T>> first;
  std::vector<comb_and_sel<T>> simp_sels;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (simple_selector_sequence), first, simp_sels)
/* clang-format on */

template <typename T>
struct type_selector : public simple_selector<T> {
  tokens::ident element_name;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (type_selector), element_name)
/* clang-format on */

template <typename T>
struct universal : public simple_selector<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (universal),)
/* clang-format on */

template <typename T>
struct hash : public simple_selector<T> {
  tokens::hash id;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (hash), id)
/* clang-format on */

/* "class" is a keyword */
template <typename T>
struct class_sel : public simple_selector<T> {
  tokens::ident name;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (class_sel), name)
/* clang-format on */

template <typename T>
struct attrib_match : public simple_selector<T> {
  tokens::ident name;
  tokens::attrib_match_type match_type;
  boost::variant<tokens::ident, tokens::string_tok> val;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (attrib_match), name, match_type, val)
/* clang-format on */

template <typename T>
struct pseudo : public selector<T> {
  virtual match::Matcher<T> makeMatcher() = 0;
};

template <typename T>
struct not_pseudo : public pseudo<T> {
  std::unique_ptr<simple_selector<T>> expr;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (not_pseudo), expr)
/* clang-format on */

struct a_n_plus_b {
  int a;
  int b;
};
/* clang-format off */
BOOST_FUSION_ADAPT_STRUCT(a_n_plus_b, a, b)
/* clang-format on */

template <typename T>
struct nth_child : public pseudo<T> {
  a_n_plus_b expr;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (nth_child), expr)
/* clang-format on */

template <typename T>
struct nth_last_child : public pseudo<T> {
  a_n_plus_b expr;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (nth_last_child), expr)
/* clang-format on */

template <typename T>
struct nth_last_of_type : public pseudo<T> {
  a_n_plus_b expr;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (nth_last_of_type), expr)
/* clang-format on */

template <typename T>
struct nth_of_type : public pseudo<T> {
  a_n_plus_b expr;
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (nth_of_type), expr)
/* clang-format on */

template <typename T>
struct empty : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T),(empty),)
/* clang-format on */

template <typename T>
struct first : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (first),)
/* clang-format on */

template <typename T>
struct first_child : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (first_child),)
/* clang-format on */

template <typename T>
struct first_of_type : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (first_of_type),)
/* clang-format on */

template <typename T>
struct last_child : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (last_child),)
/* clang-format on */

template <typename T>
struct last_of_type : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (last_of_type),)
/* clang-format on */

template <typename T>
struct only_child : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (only_child),)
/* clang-format on */

template <typename T>
struct only_of_type : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (only_of_type),)
/* clang-format on */

template <typename T>
struct root : public pseudo<T> {
  virtual match::Matcher<T> makeMatcher();
};
/* clang-format off */
BOOST_FUSION_ADAPT_TPL_STRUCT((T), (root),)
/* clang-format on */
}
}
}

#include "css.tpp"

#endif /* ___SELECTREE_CSS___ */
