#ifndef ___SELECTREE_SELECTREE___
#define ___SELECTREE_SELECTREE___

#include "match.hpp"
#include <string>

namespace selectree
{
/* requires: name -> std::string, begin -> iterator<T>, end -> iterator<T>,
 * attribute(std::string) -> boost::optional<T>, attributeKeys ->
 * iterable<std::string>, value -> std::string, id -> std::string */
/* value() is used for 'tag[key="value"]' constructions */
/* TODO: figure out how to make sure that if a reference is passed in, only
 * references will be returned in the match::Results, but if children() returns
 * values and NOT references, that T resolves to a value type. this is so that
 * in cases where we DON'T want copying (where each node has a reference to
 * another node internally), it'll return refs and not make copies (which would
 * be useless), but otherwise it'll pull values */
template <typename T>
match::Results<T> css(T, std::string);

template <typename T>
match::Results<T> xpath(T, std::string);
}

#include "SelecTree.tpp"

#endif /* ___SELECTREE_SELECTREE___ */