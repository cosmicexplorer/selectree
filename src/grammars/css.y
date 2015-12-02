/* pulled from http://www.w3.org/TR/css3-selectors/#grammar */
%ebnf

%%

selectors_group
  : selector (COMMA S* selector)*
  ;

selector
  : simple_selector_sequence (combinator simple_selector_sequence)*
  ;

combinator
  /* combinators can be surrounded by whitespace */
  : PLUS S*
  | GREATER S*
  | TILDE S*
  | S+
  ;

simple_selector_startseq
  : element_name
  | universal
  ;

simple_selector_endseq
  : HASH
  | class
  | attrib
  | pseudo
  | negation
  ;

simple_selector_sequence
  : simple_selector_startseq simple_selector_endseq*
  | simple_selector_endseq+
  ;

element_name
  : IDENT
  ;

universal
  : '*'
  ;

class
  : '.' IDENT
  ;

attrib_match
  : PREFIXMATCH
  | SUFFIXMATCH
  | SUBSTRINGMATCH
  | '='
  | INCLUDES
  | DASHMATCH
  ;

id_or_string
  : IDENT
  | STRING
  ;

attrib
  : '[' S* IDENT S* (attrib_match S* id_or_string S*)? ']'
  ;

id_or_pseudo
  : IDENT
  | functional_pseudo
  ;

pseudo
  /* '::' starts a pseudo-element, ':' a pseudo-class */
  /* Exceptions: :first-line, :first-letter, :before and :after. */
  /* Note that pseudo-elements are restricted to one per selector and */
  /* occur only in the last simple_selector_sequence. */
  : ':' ':'? id_or_pseudo
  ;

functional_pseudo
  : FUNCTION S* expression ')'
  ;

expr_alternatives
  : PLUS
  | '-'
  | DIMENSION
  | NUMBER
  | STRING
  | IDENT
  ;

expression
  /* In CSS3, the expressions are identifiers, strings, */
  /* or of the form "an+b" */
  : (expr_alternatives S*)+
  ;

negation
  : NOT S* negation_arg S* ')'
  ;

negation_arg
  : element_name
  | universal
  | HASH
  | class
  | attrib
  | pseudo
  ;
