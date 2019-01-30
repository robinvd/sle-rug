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
  Form f = parse(#Form, |cwd://./../examples/binary.myql|);
  AForm af = cst2ast(f);
  TEnv tenv = collect(af);
  UseDef usedef = resolve(af);
  msgs = check(af, tenv, usedef);

	for (m <- msgs) {
		switch (m) {
			case info(t, l): println("INFO:<l.path>:<l.begin.line>,<l.begin.column>:\n  <t>");
			case warning(t, l): println("WARN:<l.path>:<l.begin.line>,<l.begin.column>:\n  <t>");
			case error(t, l): println("ERROR:<l.path>:<l.begin.line>,<l.begin.column>:\n  <t>");
		}
	}

	if (error(_, _) <- msgs) {
		println("stopping because of previous errors");
		return;
	}

  AForm aff = flatten(af);
  compile(aff);
}
