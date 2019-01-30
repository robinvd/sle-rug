module Compile

import AST;
import Eval;

import String;
import List;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *

 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) =
  html(
    h1(f.name),
    div([form2html(q) | q<-f.questions]),
    script(src(f.src[extension="js"].file))
  );

HTML5Node form2html(ifquestion(cond, t, f)) = div([form2html(q) | q<-t+f]);
HTML5Node form2html(question(title, name, ty, nothing())) = span(h3(title), form2html(ty, name), class("<name>-parent"));
HTML5Node form2html(question(title, name, ty, just(_))) = span(h3(title), span(input(readonly(""), class(name))), class("<name>-parent"));
HTML5Node form2html(string(), str id) = input(a, class(id), oninput("run()"));
HTML5Node form2html(boolean(), str id) = input(\type("checkbox"), class(id), oninput("run()"));
HTML5Node form2html(integer(), str id) = input(\type("number"), \value(0), class(id), oninput("run()"));

str form2js(AForm f) {
  def = initialEnv(f);

  return "
    function vstr(x) {return x}
    function vint(x) {return x}
    function vbool(x) {return x}


		// latest values
    var statef = <state2js(f)>

		// map of fns that compute the value, given the state map
		var state = <state2js(def)>

    function run() {
      console.log(\'run\');
			var changed = true;

			while (changed) {
				changed = false;
				for (var i=0; i \< statef.length; i++) {
					var key = statef[i][0];
					var f = statef[i][1];
					var old_value = state[key];
					var new_value = f(state);

					if (old_value !== new_value) {
						changed = true;
					}

					state[key] = new_value;
				}
			}

			console.log(state);

      for (var key in state) {
				var new_value = state[key];

				var els = document.getElementsByClassName(key + \"-parent\");
				for (var i=0; i\<els.length; i++) {
					if (new_value === null) {
						els[i].style.display = \"none\";
					} else {
						els[i].style.display = \"block\";
					}
				}

				if (new_value !== null) {
					var els = document.getElementsByClassName(key);
					for (var i=0; i\<els.length; i++) {
							els[i].value = new_value;
							if (\'checked\' in els[i]) {
								els[i].checked = new_value;
							}
					}
				}
      }
    }
	run();
  ";
}

str state2js(AForm f) = "[<intercalate(",\n", [*state2js(x) | x<-f.questions])>]";
str state2js(map[value, value] m) =
	"{<intercalate(",\n", ["<state2js(x)> : <state2js(m[x])>" | x<-m])>}";

str state2js(ifquestion(cond, [question(title, name, ty, just(computed))], [])) =
  "[\"<name>\", (env) =\> (<state2js(cond)> ? <state2js(computed)> : null)]";

str state2js(ifquestion(cond, [question(title, name, boolean(), nothing())], [])) =
	"[\"<name>\", (env) =\> (<state2js(cond)> ? document.getElementsByClassName(\"<name>\")[0].checked : null)]";
str state2js(ifquestion(cond, [question(title, name, ty, nothing())], [])) =
	"[\"<name>\", (env) =\> (<state2js(cond)> ? document.getElementsByClassName(\"<name>\")[0].value : null)]";

str state2js(boolean()) = "false";
str state2js(integer()) = "0";
str state2js(string()) = "\"\"";

str state2js(ref(name)) = "env[\"<name>\"]";
str state2js(litInt(x)) = "<x>";
str state2js(litBool(x)) = "<x>";
str state2js(litString(x)) = x;
str state2js(binaryOp(op, l, r)) = "(<state2js(l)> <state2js(op)> <state2js(r)>)";
str state2js(unaryOp(op, v)) = "(<state2js(op)> <state2js(v)>)";

str state2js(plus()) = "+";
str state2js(sub()) = "-";
str state2js(mul()) = "*";
str state2js(div()) = "/";
str state2js(gt()) = "\>";
str state2js(lt()) = "\<";
str state2js(and()) = "&&";
str state2js(or()) = "||";
str state2js(not()) = "!";

str state2js(str s) = s;
str state2js(vstr(s)) = s;
str state2js(vint(i)) = "<i>";
str state2js(vbool(b)) = "<b>";
str state2js(Value v) = "<v>";
