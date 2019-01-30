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

Use usesQ(AExpr ae) {
  switch (ae) {
    case ref(str name): return {<ae.src, name>};
    case binaryOp(BinOp _, AExpr l, AExpr r): return usesQ(l) + usesQ(r);
    default: return {};
  }
}

Use usesQ(question(str title, str name, AType ty, just(AExpr computed))) = usesQ(computed);
Use usesQ(question(str title, str name, AType ty, nothing())) = {};

Use usesQ(ifquestion(AExpr cond, list[AQuestion] t, list[AQuestion] f)) {
  return {*usesQ(q) | q<-t + f} + usesQ(cond);
}

Use uses(AForm f) {
  return {*usesQ(q) | q<-f.questions }; 
}

Def defsQ(AQuestion q) {
  switch (q) {
    case question(str _, str name, AType _, Maybe[AExpr] _): return {<name, q.src>};
    case ifquestion(AExpr _, list[AQuestion] ts, list[AQuestion] fs): return {*defsQ(newq) | newq<-ts+fs};
    default: return {};
  }
}

Def defs(AForm f) {
  return {*defsQ(q) | q<-f.questions }; 
}
