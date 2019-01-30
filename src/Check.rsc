module Check

import IO;
import AST;
import Resolve;
import Message; // see standard library
import util::Maybe;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

Type fromAType(string()) = tstr();
Type fromAType(boolean()) = tbool();
Type fromAType(integer()) = tint();

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` )
TEnv collect(AForm f) {
  s = {};
  visit(f) {
    case question(str title, str name, AType ty, Maybe[AExpr] _, src=src): {
      s += <src, name, title, fromAType(ty)>;
    }
  }
  return s;
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  msgs = {};
  names = ();

  for (<def, name, label, ty> <- tenv) {
    // println(name);
    if (name in names) {
			if (names[name] == ty) {
				msgs += warning("dublicate question \"<name>\"", def);
			} else {
				msgs += error("dublicate question \"<name>\" with incompatible types <names[name]>/<ty> ", def);
			}
    } else {
      names[name] = ty;
    }
  }

  msgs += {*check(q, tenv, useDef) | q<-f.questions};

  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning
// - the declared type computed questions should match the type of the expression.
set[Message] check(ifquestion(cond, t, f), TEnv tenv, UseDef useDef) {
  return {*check(q, tenv, useDef) | q<-t+f};
}

set[Message] check(question(title, name, aty, maybeComputed, src=src), TEnv tenv, UseDef useDef) {
  msgs = {};

  if (just(AExpr computed) := maybeComputed) {
    msgs += check(computed, tenv, useDef);

    ty = fromAType(aty);
    tyComputed = typeOf(computed, tenv, useDef);
    if (ty != tyComputed) {
      msgs += error("could not match (question) type <ty> with <tyComputed>", src);
    }
  }

  return msgs;

}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs),
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
    case binaryOp(BinOp operand, AExpr l, AExpr r, src=src): {
      msgs += check(l, tenv, useDef) + check(r, tenv, useDef);

      tyl = typeOf(l, tenv, useDef);
      tyr = typeOf(r, tenv, useDef);
      if (tyl != tyr) {
        msgs += error("could not match (expr) type <tyl> with <tyr>", src);
      }

    }

    // etc.
  }

  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case litInt(_): return tint();
    case litBool(_): return tbool();
    case litString(_): return tstr();
    case binaryOp(plus(), AExpr l, AExpr r): return tint();
    case binaryOp(sub(), AExpr l, AExpr r): return tint();
    case binaryOp(mul(), AExpr l, AExpr r): return tint();
    case binaryOp(div(), AExpr l, AExpr r): return tint();
    case binaryOp(gt(), AExpr l, AExpr r): return tbool();
    case binaryOp(lt(), AExpr l, AExpr r): return tbool();

  }
  return tunknown();
}

/*
 * Pattern-based dispatch style:
 *
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 *
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */

