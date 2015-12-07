/* pulled from http://www.w3.org/TR/css3-selectors/#grammar */

%ebnf
%start selectors_group

%{
   var matchers = require('../css-matchers');
%}

%%

selectors_group
  : selector comma_space_selector*
      {console.log($2); return $1;}
  | error
      {return 'ERR' + $1;}
  ;

comma_space_selector
  : COMMA S* selector -> $3
  ;

comb_select_seq
  : combinator simple_selector_sequence -> $1 + $2
  ;

selector
  : simple_selector_sequence comb_select_seq*
      {console.log($2); $$ = $1;}
  ;

combinator
  /* combinators can be surrounded by whitespace */
  /* "neighbor" means have same parent */
  : PLUS S* -> $1 /* immediate neighbor */
  | TILDE S* -> $1 /* neighbor */
  | GREATER S* -> $1 /* direct descendant */
  | S+ /* descendant */
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
      {console.log($1); $$ = $1;}
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

attrib_start
  : '[' S* IDENT S*
  ;

attrib_end
  : ']'
  ;

attrib
  : attrib_start attrib_end
  | attrib_start attrib_match S* id_or_string S* attrib_end
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
  : ':' id_or_pseudo
  | ':' ':' id_or_pseudo
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
