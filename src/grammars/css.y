/* pulled from http://www.w3.org/TR/css3-selectors/#grammar */

%ebnf
%start selectors_group

/* https://github.com/zaach/jison/issues/313 */
%{
var Jison = require('jison');
var m = require('../match');
var c = require('./css-matchers');
%}

%%

selectors_group
  : selector comma_space_selector* EOF { return m.infinite($2.reduce(m.createOr, $1)); }
  | error
    {
        throw new Error("invalid selector:<" + $1 + ">");
    }
  ;

comma_space_selector
  : COMMA S* selector -> $3
  ;

comb_select_seq
  : combinator simple_selector_sequence -> {comb: $1.trim(), seq: $2}
  ;

selector
  : simple_selector_sequence comb_select_seq* -> $2.reduce(c.doCombination, $1)
  ;

/* combinators can be surrounded by whitespace */
combinator
  : PLUS S*
  | TILDE S*
  | GREATER S*
  | S+ -> 'descendant'
  ;

simple_selector_startseq
  : element_name
  | universal
  ;

hash_sel
  : HASH -> c.idSelector($1)
  ;

simple_selector_endseq
  : hash_sel
  | class
  | attrib
  | pseudo
  | negation
  ;

simple_selector_sequence
  : simple_selector_startseq simple_selector_endseq* -> $2.reduce(m.createAnd, $1)
  | simple_selector_endseq+ -> $1.reduce(m.createAnd)
  ;

/* TODO: allow OR with parens, AND with custom operator */
/* NOTE: integer tags not allowed in normal css3! this is a custom extension */
element_name
  : IDENT -> c.element($1)
  | INTEGER -> c.element($1)
  ;

universal
  : '*' -> c.universal()
  ;

class
  : '.' IDENT -> c.classSelector($2)
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
  | STRING -> $1.substr(1, $1.length - 2)
  ;

attrib_start
  : '[' S* IDENT S* -> $3
  ;

attrib_end
  : ']'
  ;

attrib
  : attrib_start attrib_end -> c.attributeExists($1)
  | attrib_start attrib_match CASEINSENSITIVEFLAG? S* id_or_string S* attrib_end
    { $$ = c.attributeMatch($1, $2, $3, $5); }
  ;

id_or_pseudofun
  : IDENT -> c.pseudoClass($1)
  | functional_pseudo
  ;

pseudo
  : ':' id_or_pseudofun -> $2
  | ':' ':' id_or_pseudofun -> c.pseudoElement($3)
  ;

function_call
  : FUNCTION -> $1.substr(0, $1.length - 2)
  ;

functional_pseudo
  : function_call S* numerical_expression S* ')' -> c.functionalPseudoClass($1, $3)
  ;

numerical_expression
  : ANPLUSB -> c.parseA_N_Plus_BExpr($1)
  | O D D -> c.parseOddExpr()
  | E V E N -> c.parseEvenExpr()
  ;

plus_minus
  : '-'
  | PLUS
  ;

negation
  : NOT S* negation_arg S* ')' -> m.createNot($3)
  ;

negation_arg
  : element_name
  | universal
  | hash_sel
  | class
  | attrib
  | pseudo
  ;
