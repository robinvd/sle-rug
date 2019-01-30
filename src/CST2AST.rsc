module CST2AST

import Syntax;
import AST;

import IO;
import util::Maybe;
import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */



AForm cst2ast(start[Form] sf) = cst2ast(sf.top);

AForm cst2ast(f:(Form)`form <Id i> { <Question* qq> }`)
  = form("<i>", [cst2ast(q) | Question q <- qq], src=f@\loc);

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`if (<Expr c>) {<Question* ts>} else {<Question* fs>}`: 
      return ifquestion(cst2ast(c), [cst2ast(q) | Question q <- ts], [cst2ast(q) | Question q <- fs], src=q@\loc);
    case (Question)`if (<Expr c>) {<Question* ts>}`: 
      return ifquestion(cst2ast(c), [cst2ast(q) | Question q <- ts], [], src=q@\loc);
    case (Question)`<Str qs> <Id name> : <Type ty> = <Expr computed>`: 
      return question("<qs>", "<name>", cst2ast(ty), just(cst2ast(computed)), src=q@\loc);
    case (Question)`<Str qs> <Id name> : <Type ty>`: 
      return question("<qs>", "<name>", cst2ast(ty), nothing(), src=q@\loc);

    default: throw "Unhandled Question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Expr l> + <Expr r>`: return binaryOp(plus(), cst2ast(l), cst2ast(r));
    case (Expr)`<Expr l> - <Expr r>`: return binaryOp(sub(), cst2ast(l), cst2ast(r));
    case (Expr)`<Expr l> * <Expr r>`: return binaryOp(mul(), cst2ast(l), cst2ast(r));
    case (Expr)`<Expr l> \> <Expr r>`: return binaryOp(gt(), cst2ast(l), cst2ast(r));
    case (Expr)`<Expr l> \< <Expr r>`: return binaryOp(lt(), cst2ast(l), cst2ast(r));
    case (Expr)`<Expr l> && <Expr r>`: return binaryOp(and(), cst2ast(l), cst2ast(r));
    case (Expr)`<Expr l> || <Expr r>`: return binaryOp(or(), cst2ast(l), cst2ast(r));
    case (Expr)`! <Expr r>`: return UnaryOp(or(), cst2ast(r));
    case (Expr)`<Int i>`: return litInt(toInt("<i>"), src=i@\loc);
    case (Expr)`<Bool b>`: switch ("<e>") {
      case "true": return litBool(true, src=b@\loc);
      case "false": return litBool(false, src=b@\loc);
      default: throw "Unhandled bool: <e>";
    }
    case (Expr)`(<Expr e>)`: return cst2ast(e, src=e@\loc);
    
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch (t) {
    case (Type)`integer`: return integer();
    case (Type)`boolean`: return boolean();
    case (Type)`string`: return string();
    default: throw "Unhandled expression: <e>";
  }
}
