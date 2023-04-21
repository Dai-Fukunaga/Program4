%{
#include <iostream> // cerr, cout
#include <set> // set
#include "types.h"

using namespace std;
using namespace clukcs;

/* Prototype for a function defined by flex. */
void yylex_destroy();

void yyerror(const char *msg)
{
	cerr << msg << endl;
}

// prototype declaration for binary_operation function
void binary_operation(class symbol_table &symtab, struct parser_val &target, struct parser_val &l_val, struct parser_val &r_val, char operation);

// prototype declaration for undeclared_error function
void undeclared_error(string variable);

string llvm_type(Type t);

string operation_code(Type t, char operation);

void load(class symbol_table &symtab, struct parser_val &target, struct parser_val &val);

void convert(class symbol_table &symtab, struct parser_val &target, struct parser_val &val, Type from, Type to);

// The unique global symbol table.
symbol_table symtab;

%}

/* Put this into the generated header file, too */
%code requires {
  	#include "types.h"
  	#include "globals.h"
}

/* Semantic value for grammar symbols.  See definition in types.h */
%define api.value.type {clukcs::parser_val}

%token IDENTIFIER INT_LITERAL FLOAT_LITERAL CHAR_LITERAL
%token '+' '-' '*' '/' '%' '=' '(' ')' '{' '}' ';' INT FLOAT CHAR RETURN


/* Which non terminal is at the top of the parse tree? */
%start program

/* Precedence */
%right '='
%left '+' '-'
%left '*' '/' '%'
%left UMINUS

%%

program: statement_list {
	cout <<
	"target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n" <<
	"target triple = \"x86_64-pc-linux-gnu\"\n" <<
	"\n" <<
	"define dso_local i32 @main() {\n" <<
		$1.code <<
	"    ret i32 0;\n" <<
	"}\n";
};

statement_list: statement_list statement {
	$$.code = $1.code + $2.code;
} | %empty {
	$$.code = ""; // code must be empty
};

statement: expression ';' {
	if ($1.addr == nullptr) { // if the expression is incorrect
		undeclared_error($1.code);
		$$.code = "";
	} else {
		$$.code = $1.code;
	}
} | '{' { symtab.push(); }  statement_list '}' {
	$$.code = $3.code;
	symtab.pop();
} | type IDENTIFIER '=' expression ';' {
	Symbol *symbol = symtab.get_local($2.code);
	if (symbol != nullptr) { // if the variable is already declared
		cerr << "cannot declare the same variable" << endl;
		$$.code = "";
	} else {
		if ($4.addr == nullptr) { // if the expression is incorrect
			undeclared_error($4.code);
			$$.code = "";
		} else {
			symtab.put($2.code, $1.type);
			// change the type
			struct parser_val l_val, r_val;
			$$.code = $4.code;
			Variable *var = symtab.make_variable($2.code);
			$2.code = ""; // identifier's code must be empty after declaration
			$$.code += "    " + var->location()->name() + " = alloca " + llvm_type($1.type) + "\n";
			load(symtab, $$, $4);
			convert(symtab, $$, $4, $4.type, $1.type);
			$$.code += "    store " + llvm_type($1.type) + " " + $4.addr->name() + ", " + llvm_type($4.type) + " *" + var->location()->name() + "\n";
		}
	}
} | type IDENTIFIER ';' {
	Symbol *symbol = symtab.get_local($2.code);
	if (symbol != nullptr) { // if the variable is already declared
		cerr << "cannot declare the same variable" << endl;
		$$.code = "";
	} else {
		symtab.put($2.code, $1.type);
		Variable *var = symtab.make_variable($2.code);
		$2.code = "";
		$$.code = "    " + var->location()->name() + " = alloca " + llvm_type($1.type) + "\n";
	}
} | RETURN expression ';' {
	if ($2.addr == nullptr) {
		undeclared_error($2.code);
		$$.code = "";
	} else {
		$$.code = $2.code;
		load(symtab, $$, $2);
		convert(symtab, $$, $2, $2.type, Type::Int);
		$$.code += "    ret i32 " + $2.addr->name() + "\n";
	}
} | error ';' { // error is a special token defined by bison
	$$.code = "";
	yyerrok;
};

type: INT {
	$$.type = Type::Int;
} | FLOAT {
	$$.type = Type::Float;
} | CHAR {
	$$.type = Type::Char;
};

expression: expression '+' expression {
	binary_operation(symtab, $$, $1, $3, '+');
} | expression '-' expression {
	binary_operation(symtab, $$, $1, $3, '-');
} | expression '*' expression {
	binary_operation(symtab, $$, $1, $3, '*');
} | expression '/' expression {
	binary_operation(symtab, $$, $1, $3, '/');
} | expression '%' expression {
	binary_operation(symtab, $$, $1, $3, '%');
} | expression '=' expression {
	if ($1.addr == nullptr || $3.addr == nullptr) { // if the expression is incorrect
		if ($1.addr == nullptr) {
			undeclared_error($1.code);
		}
		if ($3.addr == nullptr) {
			undeclared_error($3.code);
		}
		$$.code = "";
		$$.addr = nullptr;
		$$.type = Type::Unknown;
	} else {
		if (dynamic_cast<Variable *>($1.addr) == nullptr) {
			cerr << "left-hand-side of an assignment must be a variable" << endl;
			$$.code = "";
			$$.addr = nullptr;
			$$.type = Type::Unknown;
		} else {
			$$.code = $1.code + $3.code;
			load(symtab, $$, $3);
			convert(symtab, $$, $3, $3.type, $1.type);
			$$.type = $1.type;
			$$.addr = $1.addr; // attention!!!
			Variable *var = symtab.make_variable($1.addr->name());
			$$.code += "    store " + llvm_type($1.type) + " " + $3.addr->name() + ", " + llvm_type($3.type) + " *" + var->location()->name() + "\n";
		}
	}
} | '-' expression %prec UMINUS {
	if ($2.addr != nullptr) {
		$$.code = $2.code;
		load(symtab, $$, $2);
		if ($2.type == Type::Float) {
			$$.addr = symtab.make_temp($2.type);
			$$.code += "    " + $$.addr->name() + " = fneg float " + $2.addr->name() + "\n";
			$$.type = $2.type;
		} else if ($2.type == Type::Int || $2.type == Type::Char) {
			struct parser_val val;
			val.code = "";
			val.addr = symtab.make_int_const(0);
			val.type = Type::Int;
			binary_operation(symtab, $$, val, $2, '-');
		}
	} else { // if the expression is incorrect
		undeclared_error($2.code);
		$$.addr = nullptr;
		$$.code = "";
		$$.type = Type::Unknown;
	}
} | '(' expression ')' {
	if ($2.addr != nullptr) {
		$$.code = $2.code;
		$$.addr = $2.addr;
		$$.type = $2.type;
	} else { // if the expression is incorrect
		undeclared_error($2.code);
		$$.addr = nullptr;
		$$.code = "";
		$$.type = Type::Unknown;
	}
} | INT_LITERAL {
	$$.code = "";
	int val = stol($1.code);
	$$.addr = symtab.make_int_const(val);
	$$.type = Type::Int;
} | FLOAT_LITERAL {
	$$.code = "";
	float val = stof($1.code);
	$$.addr = symtab.make_float_const(val);
	$$.type = Type::Float;
} | CHAR_LITERAL {
	$$.code = "";
	char c = $1.code[1];
	$$.addr = symtab.make_char_const(c);
	$$.type = Type::Char;
} | IDENTIFIER {
	$$.addr = symtab.make_variable($1.code);
	if ($$.addr == nullptr) {
		$$.type = Type::Unknown;
		$$.code = $1.code;
	} else {
		$$.type = $$.addr->type();
		$$.code = "";
	}
};


%%

int main() {
	int result = yyparse();
	yylex_destroy();
	return result;
}

/**
 * @brief calculate binary operaion
 *
 * @param symtab symbol table to get identifiers
 * @param target target expression
 * @param l_val the expression
 * @param r_val the expression
 * @param operation operation (+, -, *, /, and %)
 */
void binary_operation(class symbol_table &symtab, struct parser_val &target, struct parser_val &l_val, struct parser_val &r_val, char operation) {
	if (l_val.addr == nullptr || r_val.addr == nullptr) {
		if (l_val.addr == nullptr) {
			undeclared_error(l_val.code);
		}
		if (r_val.addr == nullptr) {
			undeclared_error(r_val.code);
		}
		target.code = "";
		target.addr = nullptr;
		target.type = Type::Unknown;
	} else {
		if (operation == '%') {
			if (l_val.type == Type::Float || r_val.type == Type::Float) {
				cerr << "cannot use % to float" << endl;
				target.code = "";
				target.addr = nullptr;
				target.type = Type::Unknown;
				return;
			}
		}
		target.code = l_val.code + r_val.code;
		load(symtab, target, l_val);
		load(symtab, target, r_val);
		if (l_val.type < r_val.type) {
			convert(symtab, target, l_val, l_val.type, r_val.type);
		}
		if (l_val.type > r_val.type) {
			convert(symtab, target, r_val, r_val.type, l_val.type);
		}

		target.addr = symtab.make_temp(l_val.type);
		target.type = target.addr->type();
		string opcode = operation_code(target.type, operation);
		target.code += "    " + target.addr->name() + " = " + opcode + " " + llvm_type(target.type) + " " + l_val.addr->name() + ", " + r_val.addr->name() + "\n";
	}
}

/**
 * @brief make a standard error for undeclared variables
 *
 * @param variable undeclared variable
 */
void undeclared_error(string variable) {
	static set<string> variables;
	variables.insert("");
	if (variables.find(variable) == variables.end()) {
		cerr << "'" << variable << "'" << " was not declared" << endl;
		variables.insert(variable);
	}
}

/**
 * @brief get a llvm type
 *
 * @param t type to know llvm type
 * @return string llvm type
 */
string llvm_type(Type t) {
	if (t == Type::Int) {
		return "i32";
	} else if (t == Type::Float) {
		return "float";
	} else if (t == Type::Char) {
		return "i8";
	}
	return "";
}

/**
 * @brief get a operation code
 *
 * @param t operation type
 * @param operation +, -, *, /, or %
 * @return string operation code
 */
string operation_code(Type t, char operation) {
	if (operation == '+') {
		if (t == Type::Float) {
			return "fadd";
		} else if (t == Type::Int || t == Type::Char) {
			return "add";
		}
	} else if (operation == '-') {
		if (t == Type::Float) {
			return "fsub";
		} else if (t == Type::Int || t == Type::Char) {
			return "sub";
		}
	} else if (operation == '*') {
		if (t == Type::Float) {
			return "fmul";
		} else if (t == Type::Int || t == Type::Char) {
			return "mul";
		}
	} else if (operation == '/') {
		if (t == Type::Float) {
			return "fdiv";
		} else if (t == Type::Int || t == Type::Char) {
			return "sdiv";
		}
	} else if (operation == '%') {
		if (t == Type::Int || t == Type::Char) {
		return "srem";
		}
	}
	return "";
}

/**
 * @brief make a load code
 *
 * @param symtab symbol table to get identifiers
 * @param target target expression
 * @param val expression
 */
void load(class symbol_table &symtab, struct parser_val &target, struct parser_val &val) {
	if (dynamic_cast<Variable *>(val.addr) != nullptr) {
		Variable *var = symtab.make_variable(val.addr->name());
		val.type = val.addr->type();
		val.addr = symtab.make_temp(val.type);
		target.code += "    " + val.addr->name() + " = load " + llvm_type(val.type) + ", " + llvm_type(val.type) + " *" + var->location()->name() + "\n";
	}
}

/**
 * @brief change the type
 *
 * @param symtab symbol table to get identifiers
 * @param target target expression
 * @param val expression
 * @param from original type
 * @param to destination type
 */
void convert(class symbol_table &symtab, struct parser_val &target, struct parser_val &val, Type from, Type to) {
	if (from < to) {
		string name = val.addr->name();
		val.type = to;
		val.addr = symtab.make_temp(to);
		target.code += "    " + val.addr->name() + (to == Type::Int ? " = sext " : " = sitofp ") + llvm_type(from) + " " + name + " to " + llvm_type(to) + "\n";
	} else if (from > to) {
		string name = val.addr->name();
		val.type = to;
		val.addr = symtab.make_temp(to);
		target.code += "    " + val.addr->name() + (from == Type::Int ? " = trunc " : " = fptosi ") + llvm_type(from) + " " + name + " to " + llvm_type(to) + "\n";
	}
}
