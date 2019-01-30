module Run

import IO;
import ParseTree;
import AST;
import Syntax;
import Resolve;
import Transform;
import CST2AST;
import Check;
import Compile;
import Message;

void main(list[str] args) {
  Form f = parse(#start[Form], |cwd://./../examples/tax.myql|);
  AForm af = cst2ast(f);
  TEnv tenv = collect(af);
  UseDef usedef = resolve(af);
  msgs = check(af, tenv, usedef);

	for (m <- msgs) {
		println("<m>");
	}

	if (error(_, _) <- msgs) {
		println("stopping because of previous errors");
		return;
	}

  AForm aff = flatten(af);
  compile(aff);
}
