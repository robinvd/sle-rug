module Transform

import Resolve;
import AST;

/*
 * Transforming QL forms
 */


/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; if (a) { if (b) { q1: "" int; } q2: "" int; }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */

AForm flatten(form(name, qs, src=src)) =
  form(name, [*flatten(litBool(true), q) | q<-qs], src=src);

list[AQuestion] flatten(AExpr acc, ifquestion(cond, t, f)) =
  [*flatten(binaryOp(and(), acc, cond), nq) | nq <- t] + 
  [*flatten(binaryOp(and(), acc, unaryOp(not(), cond)), nq) | nq <- f];
list[AQuestion] flatten(AExpr acc, question(title, name, ty, comp)) =
  [ifquestion(acc, [question(title, name, ty, comp)], [])];

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 * Bonus: do it on concrete syntax trees.
 */
 
 AForm rename(AForm f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

