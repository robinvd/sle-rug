module AST

import util::Maybe;

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;

data AQuestion(loc src = |tmp:///|)
  = ifquestion(AExpr cond, list[AQuestion] t, list[AQuestion] f)
  | question(str title, str name, AType ty, Maybe[AExpr] computed)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | litInt(int i)
  | litBool(bool b)
  | litString(str s)
  | binaryOp(BinOp op, AExpr l, AExpr r)
  | unaryOp(UnOp uop, AExpr e)
  ;

data BinOp
  = plus()
  | sub()
  | mul()
  | div()
  | gt()
  | lt()
  | and()
  | or()
  ;

data UnOp
  = not()
  ;

data AType(loc src = |tmp:///|)
  = string()
  | boolean()
  | integer()
  ;
