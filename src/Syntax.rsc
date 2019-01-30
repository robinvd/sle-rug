module Syntax

extend lang::std::Comment;
extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form
  = "form" Id "{" Question* "}";

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = "if" "(" Expr ")" "{" Question* "}" "else" "{" Question* "}"
  | "if" "(" Expr ")" "{" Question* "}"
  | Str Id ":" Type "=" Expr
  | Str Id ":" Type
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Int
  | Bool
  | left Expr "*" Expr
  > left Expr "-" Expr
  > left Expr "+" Expr
  > left Expr "\>" Expr
  > left Expr "\<" Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  > "!" Expr
  | "(" Expr ")"
  ;

syntax Type
  = Integer:"integer"
  | Boolean:"boolean"
  | String:"string"
  ;

lexical Str = "\"" ![\"]*  "\"";

lexical Int
  = "-"?[0-9]+;

lexical Bool = ("true" | "false");



