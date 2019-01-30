module Resolve

import AST;
import util::Maybe;

/*
 * Name resolution for QL
 */


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];

UseDef resolve(AForm f) = uses(f) o defs(f);

/*
 * Find all uses by traversing the tree until a ref is found.
 */
Use usesQ(ref(str name, src=src)) = {<src, name>};
Use usesQ(binaryOp(BinOp _, AExpr l, AExpr r)) = usesQ(l) + usesQ(r);
Use usesQ(AExpr _) = {};

Use usesQ(question(str title, str name, AType ty, just(AExpr computed))) = usesQ(computed);
Use usesQ(question(str title, str name, AType ty, nothing())) = {};

Use usesQ(ifquestion(AExpr cond, list[AQuestion] t, list[AQuestion] f)) =
  {*usesQ(q) | q<-t + f} + usesQ(cond);

Use uses(AForm f) = {*usesQ(q) | q<-f.questions }; 

/*
 * Find all defs by traversing the tree until a question is found.
 */
Def defsQ(question(str _, str name, AType _, Maybe[AExpr] _, src=src)) = {<name, src>};
Def defsQ(ifquestion(AExpr _, list[AQuestion] ts, list[AQuestion] fs)) =
  {*defsQ(newq) | newq<-ts+fs};

Def defs(AForm f) = {*defsQ(q) | q<-f.questions }; 
