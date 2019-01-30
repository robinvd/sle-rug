module Eval

import AST;
import Resolve;
import Check;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  TEnv tenv = collect(f);
  return (name: defaultValue(ty) | <_, name, _, ty> <- tenv);
}

Value defaultValue(tint()) = vint(0);
Value defaultValue(tbool()) = vbool(false);
Value defaultValue(tstr()) = vstr("");

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (q <- f.questions) {
    venv = eval(q, inp, venv);
  }

  return venv;
}

VEnv eval(ifquestion(cond, t, f), Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  if (vbool(eval_cond) := eval(cond, venv)) {
    if (eval_cond) {
      for (q <- t) {
        venv = eval(q, inp, venv);
      }
    } else {
      for (q <- f) {
        venv = eval(q, inp, venv);
      }
    }
  } else {
    throw "Unsupported expression <e>";
  }

  return venv;
}
VEnv eval(question(title, name, ty, maybeComputed), Input inp, VEnv venv) {
  if (just(computed) := maybeComputed) {
    venv[name] = eval(computed, venv);
  } else if (name == inp.question) {
    venv[name] = inp.\value;
  }

  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    case litInt(i): return vint(i);
    case litBool(b): return vbool(b);
    case litString(s): return vstr(s);
    case binaryOp(op, l, r): {
      le = eval(l, venv);
      re = eval(r, venv);
      if (<vint(ll), vint(rr)> := <le, re>) {
        switch (op) {
          case plus(): return vint(ll + rr);
          case sub(): return vint(ll - rr);
          case mul(): return vint(ll * rr);
          case gt(): return vbool(ll > rr);
          case lt(): return vbool(ll < rr);
        }
      }
      if (<vbool(ll), vbool(rr)> := <le, re>) {
        switch (op) {
          case and(): return vbool(ll && rr);
          case or(): return vbool(ll || rr);
        }
      }
    }
    case unaryOp(not(), vbool(b)): return vbool(!b);
    
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
}
