/* pulled from http://www.w3.org/TR/css3-selectors/#grammar */

%ebnf
%start selectors_group

%{
var Jison = require('jison');
var m = require('./css-matchers');
%}

%%

selectors_group
  : selector comma_space_selector*
      {return [$1].concat($2);}
  | error
      {return 'ERR: ' + $1;}
  ;

comma_space_selector
  : COMMA S* selector -> $3
  ;

comb_select_seq
  : combinator simple_selector_sequence -> {combinator: $1, seq: $2}
  ;

selector
  : simple_selector_sequence comb_select_seq* -> m.doCombination($1, $2)
  ;

combinator
  /* combinators can be surrounded by whitespace */
  /* "neighbor" means have same parent */
  : PLUS S* -> $1 /* immediate neighbor */
  | TILDE S* -> $1 /* neighbor */
  | GREATER S* -> $1 /* direct descendant */
  | S+ -> 'descendant' /* descendant */
  ;

simple_selector_startseq
  : element_name
  | universal
  ;

hash_sel
  : HASH -> m.idSelector($1)
  ;

simple_selector_endseq
  : hash_sel
  | class
  | attrib
  | pseudo
  | negation
  ;

simple_selector_sequence
  : simple_selector_startseq simple_selector_endseq*
      {$$ = m.combineSimpleSelectorSequence([$1].concat($2));}
  | simple_selector_endseq+ -> m.combineSimpleSelectorSequence($1)
  ;

element_name
  : IDENT -> m.element($1)
  ;

universal
  : '*' -> m.element($1)
  ;

class
  : '.' IDENT -> m.classSelector($2)
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
  | STRING -> $1.substr(0, $1.length - 2)
  ;

attrib_start
  : '[' S* IDENT S* -> $3
  ;

attrib_end
  : ']'
  ;

attrib
  : attrib_start attrib_end -> m.attributeExists($1)
  | attrib_start attrib_match S* id_or_string S* attrib_end
      {$$ = m.attributeMatch($1, $2, $4);}
  ;

id_or_pseudofun
  : IDENT
  | functional_pseudo
  ;

pseudo
  /* '::' starts a pseudo-element, ':' a pseudo-class */
  /* Exceptions: :first-line, :first-letter, :before and :after. */
  /* Note that pseudo-elements are restricted to one per selector and */
  /* occur only in the last simple_selector_sequence. */
  : ':' id_or_pseudofun -> m.pseudoClass($2)
  | ':' ':' id_or_pseudofun -> m.pseudoElement($3)
  ;

function_call
  : FUNCTION -> m.parseFunctionalPseudoClass($1)
  ;

functional_pseudo
  : function_call S* expression S* ')' -> m.functionalPseudoClass($1, $3)
  ;

/* amending this from the given grammar to match the 'nth' grammar, given in
   the same document cited above. all functional pseudo-classes only accept
   "an+b"-type expressions */
/* nth */
expression
  : a_n_plus_b -> m.parseA_N_Plus_BExpr($1)
  | O D D -> m.parseOddExpr()
  | E V E N -> m.parseEvenExpr()
  ;

a_n_plus_b
  : ('-'|'+')? INTEGER? N (('-'|'+') INTEGER)?
  ;

negation
  : NOT S* negation_arg S* ')' -> m.negationPseudoClass($3)
  ;

negation_arg
  : element_name
  | universal
  | hash_sel
  | class
  | attrib
  | pseudo
  ;
