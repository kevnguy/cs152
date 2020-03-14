%{
    #define YY_NO_UNPUT
    #include <stdio.h>
    #include <stdlib.h>
    #include <map>
    #include <string.h>
    #include <iostream>
    #include <sstream>
    #include <cstring>
    #include <string>
    #include <vector>
    #include <set>
    using namespace std;

    int temp_num = 0;
    int label_num = 0;
    extern char* yytext;
    extern int currPos;
    map<string, string> tempVars;
    map<string, int> arrSize;
    bool existsMain = false;
    set<string> predefFuncs;
    set<string> reservedWords {"NUMBER", "IDENT", "RETURN", "FUNCTION", "SEMICOLON", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY",
        "CONTINUE", "ENDIF", "OF", "READ", "WRITE", "DO", "WHILE", "FOR", "TRUE", "FALSE", "ASSIGN", "EQ", "NEQ", "LT", "LTE", "GT", "GTE", "ADD", "SUB", "MULT", "DIV",
        "END_BODY", "BEGINLOOP", "ENDLOOP", "COLON", "INTEGER", "COMMA", "ARRAY", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "L_PAREN", "R_PAREN", "IF", "ELSE", "THEN",
        "MOD", "AND", "OR", "NOT", "function", "declarations", "declaration", "vars", "var", "expressions", "expression", "idents", "ident", "bool-expr",
        "relation-and-expr", "relation-expr-inv", "relation-expr", "comp", "multiplicative-expr", "term", "statements", "statement"};

    string make_temp();
    string make_label();
    void yyerror(const char* s);
    int yylex();
    extern FILE* yyin;

%}

%union{
  int		num;
  char*	    ident;

  struct A {
      bool  is_arr;
      char* ret_name;
      char* code;
  } expression;

  struct B {
      char* code;
  } statement;
}

%start	program
%token  <ident> IDENT
%token  <num> NUMBER
%type   <expression> relation-expr comp multiplicative-expr term bool-expr relation-and-expr relation-expr-inv
%type   <expression> function func_ident declarations idents ident declaration vars var expressions expression
%type   <statement> statements statement

%token  RETURN FUNCTION SEMICOLON BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY BEGINLOOP ENDLOOP
%token  IF ELSE THEN ENDIF OF
%token  CONTINUE
%token  READ WRITE
%token  DO WHILE FOR
%token  TRUE FALSE
%token  COLON INTEGER COMMA ARRAY L_SQUARE_BRACKET R_SQUARE_BRACKET L_PAREN R_PAREN
%left   ASSIGN EQ NEQ LT LTE GT GTE ADD SUB MULT DIV MOD AND OR
%right  NOT

%%
program:	%empty	{
                if (!existsMain) {
                    cout << "Missing main function declaration" << endl;
                }
            }
            | function program  {};

function:   FUNCTION func_ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
                stringstream ss;
                ss << "func " << $2.ret_name << "\n";
                string s = $2.ret_name;
                if (s == "main") {
                    existsMain = true;
                }
                ss << $5.code;
                string decs = $5.code;
                int decNum = 0;
                while(decs.find(".") != string::npos) { //find a .
                    int pos = decs.find(".");
                    decs.replace(pos, 1, "=");
                    string part = ", $" + to_string(decNum) + "\n";
                    decNum++;
                    decs.replace(decs.find("\n", pos), 1, part);
                }
                ss << decs << $8.code;
                string statements = $11.code;
                if (statements.find("continue") != string::npos) {
                    cout << "ERROR: Continue is outside loop in function " << $2.ret_name << endl;
                }
                ss << statements << "endfunc\n\n";
                string temp = ss.str();
                cout << temp;
            };

declarations:   declaration SEMICOLON declarations {
                    stringstream ss;
                    ss << $1.code << $3.code;
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                }
                | %empty {
                    $$.ret_name = strdup("");
                    $$.code = strdup("");
                };

declaration:    idents COLON INTEGER {
                    stringstream ss;
                    int left = 0;
                    int right = 0;
                    string parse($1.ret_name);
                    bool ex = false;
                    while(!ex) {
                        right = parse.find("/", left);
                        ss << ". ";
                        if (right == string::npos) {
                            string ident = parse.substr(left, right);
                            if (reservedWords.find(ident) != reservedWords.end()) {
                                cout << "Identifier " << ident.c_str() << " is a reserved word." << endl;
                            }
                            if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                                cout << "Identifier " << ident.c_str() << " was previously declared" << endl;
                            } else {
                                tempVars[ident] = ident;
                                arrSize[ident] = 1;
                            }
                            ss << ident;
                            //temp.append(ident);
                            ex = true;
                        } else {
                            string ident = parse.substr(left, right-left);
                            if (reservedWords.find(ident) != reservedWords.end()) {
                                cout << "Identifier " << ident.c_str() << " is a reserved word." << endl;
                            }
                            if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                                cout << "Identifier " << ident.c_str() << " was previously declared." << endl;
                            } else {
                                tempVars[ident] = ident;
                                arrSize[ident] = 1;
                            }
                            ss << ident;
                            //temp.append(ident);
                            left = right + 1;
                        }
                        ss << "\n";
                    }
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                }
    | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER  {
            stringstream ss;
            size_t left = 0;
            size_t right = 0;
            string parse($1.ret_name);
            bool ex = false;
            while(!ex) {
                right = parse.find("/", left);
                ss << ".[] ";
                if (right == string::npos) {
                    string ident = parse.substr(left, right);
                    if (reservedWords.find(ident) != reservedWords.end()) {
                        cout << "Identifier name" << ident.c_str() << " is a reserved word." << endl;
                    }
                    if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                        cout << "Identifier " << ident.c_str() << " was previously declared" << endl;
                    } else {
                        if ($5 <= 0) {
                            cout << "Declaring and array ident " << ident.c_str() << " of size less than or equal to 0." << endl;
                        }
                        tempVars[ident] = ident;
                        arrSize[ident] = $5;
                    }
                    ss << ident;
                    ex = true;
                } else {
                    string ident = parse.substr(left, right-left);
                    if (reservedWords.find(ident) != reservedWords.end()) {
                        cout << "Identifier " << ident.c_str() << " shares a name with a reserved word" << endl;
                    }
                    if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                        cout << "Identifier " << ident.c_str() << " was previously declared" << endl;
                    } else {
                        if ($5 <= 0) {
                            cout << "Declaring array ident " << ident.c_str() << " of size less than or equal to 0" << endl;
                        }
                        tempVars[ident] = ident;
                        arrSize[ident] = $5;
                    }
                    ss << ident;
                    left = right + 1;
                }
                ss << ", " << to_string($5) << "\n";
            }
            string temp = ss.str();
            $$.code = strdup(temp.c_str());
            $$.ret_name = strdup("");
        };

func_ident:	IDENT {
                if (predefFuncs.find($1) != predefFuncs.end()) {
                    cout << "function name " << $1 << " already declared." << endl;
                } else {
                    predefFuncs.insert($1);
                }
            	$$.ret_name = strdup($1);
            	$$.code = strdup("");
            }

ident:      IDENT {
                $$.ret_name = strdup($1);
                $$.code = strdup("");
            };

idents:     ident {
                $$.ret_name = strdup($1.ret_name);
                $$.code = strdup("");
            }
            | ident COMMA idents  {
                stringstream ss;
                ss << $1.ret_name << "/" << $3.ret_name;
                string temp = ss.str();
                $$.ret_name = strdup(temp.c_str());
                $$.code = strdup("");
            };

statements: statement SEMICOLON statements {
                stringstream ss;
                ss << $1.code << $3.code;
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                //no need to set ret_name
            }
            | statement SEMICOLON {
                $$.code = strdup($1.code);
                //no need to set ret_name
            };

statement:  var ASSIGN expression {
                stringstream ss;
                ss << $1.code << $3.code;
                string expr = $3.ret_name;
                if ($1.is_arr && $3.is_arr) {
                    ss << "[]= ";
                } else if ($1.is_arr) {
                    ss << "[]= ";
                } else if ($3.is_arr) {
                    ss << "= ";
                } else {
                    ss << "= ";
                }
                ss << $1.ret_name << ", " << expr << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
            | IF bool-expr THEN statements ENDIF {
                stringstream ss;
                string label0 = make_label();
                string label1 = make_label();
                ss << $2.code;
                ss << "?:= " << label0 << ", " << $2.ret_name << "\n";
                ss << ":= " << label1 << "\n";
                ss << ": " << label0 << "\n";
                ss << $4.code;
                ss << ": " << label1 << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
            | IF bool-expr THEN statements ELSE statements ENDIF {
                stringstream ss;
                string label0 = make_label();
                string label1 = make_label();
                ss << $2.code;
                ss << "?:= " << label0 << ", " << $2.ret_name << "\n";
                ss << $6.code;
                ss << ":= " << label1 << "\n ";
                ss << ": " << label0 << "\n";
                ss << $4.code;
                ss << ": " << label1 << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
            | WHILE bool-expr BEGINLOOP statements ENDLOOP {
                stringstream ss;
                string label0 = make_label();
                string label1 = make_label();
                string label2 = make_label();
                string code = $4.code;
                size_t pos = code.find("continue");
                while (pos != string::npos) {
                    code.replace(pos, 8, ":= "+label0);
                    pos = code.find("continue");
                }
                ss << ": " << label0 << "\n";
                ss << $2.code;
                ss << "?:= " << label1 << ", ";
                ss << $2.ret_name << "\n";
                ss << ":= " << label2 << "\n";
                ss << ": " << label1 << "\n";
                ss << code;
                ss << ":= " << label0 << "\n";
                ss << ": " << label2 << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
    | DO BEGINLOOP statements ENDLOOP WHILE bool-expr {
        stringstream ss;
        string label0 = make_label();
        string label1 = make_label();
        string statCode = $3.code;
        size_t pos = statCode.find("continue");
        while (pos != string::npos) {
            statCode.replace(pos, 8, ":= "+label1);
            pos = statCode.find("continue");
        }
        ss << ": " << label0 << "\n" << statCode;
        ss << ": " << label1 << "\n";
        ss << $6.code;
        ss << "?:= " << label0 << ", ";
        ss << $6.ret_name << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
    }
    | FOR var ASSIGN NUMBER SEMICOLON bool-expr SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {
        stringstream ss;
        string temp0 = make_temp();
        string label0 = make_label();
        string label1 = make_label();
        string label2 = make_label();
        string label3 = make_label();
        string statCode = $12.code;
        size_t pos = statCode.find("continue");
        while (pos != string::npos) {
            statCode.replace(pos, 8, ":= "+label2);
            pos = statCode.find("continue");
        }
        ss << $2.code;
        string middle = to_string($4);
        if ($2.is_arr) {
            ss << "[]= ";
        } else {
            ss << "= ";
        }
        ss << $2.ret_name << ", " << middle << "\n" << ": " << label0 << "\n";
        ss << $6.code;
        ss << "?:= " << label1 << ", ";
        ss << $6.ret_name << "\n";
        ss << ":= " << label3 << "\n";
        ss << ": " << label1 << "\n";
        ss << statCode;
        ss << ": "<< label2 << "\n" << $8.code << $10.code;
        if ($8.is_arr) {
            ss << "[]= ";
        } else {
            ss << "[]= ";
        }
        ss << $8.ret_name << ", " << $10.ret_name << "\n";
        ss << ":= " << label0 << "\n";
        ss << ": " << label3 << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
    }
    | READ vars {
        string temp;
        temp.append($2.code);
        size_t pos = temp.find("/", 0);
        while(pos != string::npos) {
            temp.replace(pos, 1, "<");
            pos = temp.find("/", pos);
        }
        $$.code = strdup(temp.c_str());
    }
    | WRITE vars {
        string temp;
        temp.append($2.code);
        size_t pos = temp.find("/", 0);
        while(pos != string::npos) {
            temp.replace(pos, 1, ">");
            pos = temp.find("/", pos);
        }
        $$.code = strdup(temp.c_str());
    }
    | CONTINUE {
        $$.code = strdup("continue\n");
    }
    | RETURN expression {
        stringstream ss;
        ss << $2.code << "ret " << $2.ret_name << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
    };

bool-expr:  relation-and-expr OR bool-expr {
        stringstream ss;
        string temp0 = make_temp();
        ss << $1.code << $3.code;
        ss << ". " << temp0 << "\n";
        ss << "|| "<< temp0 << ", ";
        ss << $1.ret_name << ", " << $3.ret_name << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(temp0.c_str());
    }
    | relation-and-expr {
        $$.code = strdup($1.code);
        $$.ret_name = strdup($1.ret_name);
    };

relation-and-expr: relation-expr-inv AND relation-and-expr {
        stringstream ss;
        string temp0 = make_temp();
        ss << $1.code << $3.code;
        ss << ". " << temp0 << "\n";
        ss << "&& " << temp0 << ", ";
        ss << $1.ret_name << ", " << "$3.ret_name" << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(temp0.c_str());
    }
    | relation-expr-inv {
        $$.code = strdup($1.code);
        $$.ret_name = strdup($1.ret_name);
    };

relation-expr-inv:  NOT relation-expr-inv {
        stringstream ss;
        string temp0 = make_temp();
        ss << $2.code;
        ss << ". " << temp0 << "\n";
        ss << "! " <<temp0 << ", ";
        ss << $2.ret_name << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(temp0.c_str());
    }
    | relation-expr {
        $$.code = strdup($1.code);
        $$.ret_name = strdup($1.ret_name);
    }

relation-expr:  expression comp expression {
        stringstream ss;
        string temp0 = make_temp();
        ss << $1.code << $3.code;
        ss << ". " << temp0 << "\n" << $2.ret_name << temp0 << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(temp0.c_str());
    }
    | TRUE {
        string temp;
        temp.append("1");
        $$.code = strdup("");
        $$.ret_name = strdup(temp.c_str());
    }
    | FALSE {
        string temp;
        temp.append("0");
        $$.code = strdup("");
        $$.ret_name = strdup(temp.c_str());
    }
    | L_PAREN bool-expr R_PAREN {
        $$.code = strdup($2.code);
        $$.ret_name = strdup($2.ret_name);
    };

comp:   EQ {
            $$.code = strdup("");
            $$.ret_name = strdup("== ");
        }
        | NEQ {
            $$.code = strdup("");
            $$.ret_name = strdup("!= ");
        }
        | LT {
            $$.code = strdup("");
            $$.ret_name = strdup("< ");
        }
        | LTE {
            $$.code = strdup("");
            $$.ret_name = strdup("<= ");
        }
        | GT {
            $$.code = strdup("");
            $$.ret_name = strdup("> ");
        }
        | GTE {
            $$.code = strdup("");
            $$.ret_name = strdup(">= ");
        };

expression: multiplicative-expr ADD expression {
                stringstream ss;
                string temp0 = make_temp();
                ss << $1.code << $3.code;
                ss << ". " << temp0 << "\n";
                ss << "+ " << temp0 << ", ";
                ss << $1.ret_name << ", " << $3.ret_name << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | multiplicative-expr SUB expression {
                stringstream ss;
                string temp0 = make_temp();
                ss << $1.code << $3.code;
                ss << ". " << temp0 << "\n";
                ss << "- " << temp0 << ", ";
                ss << $1.ret_name << ", " << $3.ret_name << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | multiplicative-expr {
                $$.code = strdup($1.code);
                $$.ret_name = strdup($1.ret_name);
            };

multiplicative-expr: term MULT multiplicative-expr {
                stringstream ss;
                string temp0 = make_temp();
                ss << $1.code << $3.code << ". " << temp0 << "\n";
                ss << "* " << temp0 << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | term DIV multiplicative-expr {
                stringstream ss;
                string temp0 = make_temp();
                ss << $1.code << $3.code << ". " << temp0 << "\n";
                ss << "/ " << temp0 << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | term MOD multiplicative-expr {
                stringstream ss;
                string temp0 = make_temp();
                ss << $1.code << $3.code << ". " << temp0 << "\n";
                ss << "% t" << temp0 << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | term {
                $$.code = strdup($1.code);
                $$.ret_name = strdup($1.ret_name);
            };

term:       SUB var {
                stringstream ss;
                string temp0 = make_temp();
                //string temp;
                if ($2.is_arr) {
                    ss << $2.code << ". " << temp0 << "\n";
                    ss << "=[] " << temp0 << ", " << $2.ret_name << "\n";
                } else {
                    ss << ". " << temp0 << "\n";
                    ss << "= " << temp0 << ", " << $2.ret_name << "\n";
                    ss << $2.code;
                }
                if (tempVars.find($2.ret_name) != tempVars.end()) {
                    tempVars[$2.ret_name] = temp0;
                }
                ss << "* " << temp0 << ", " << temp0 << "-1\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | SUB NUMBER {
                stringstream ss;
                string temp0 = make_temp();
                ss << ". " << temp0 << "\n";
                ss << "= " << temp0 << ", -" << to_string($2) << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | SUB L_PAREN expression R_PAREN {
                stringstream ss;
                ss << $3.code << "* " << $3.ret_name << ", -1\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup($3.ret_name);
            }
            | var {
                stringstream ss;
                string temp0 = make_temp();
                if ($1.is_arr) {
                    ss << $1.code << ". " << temp0 << "\n";
                    ss << "=[] " << temp0 << ", " << $1.ret_name << "\n";
                } else {
                    ss << ". " << temp0 << "\n";
                    ss << "= " << temp0 << ", " << $1.ret_name << "\n";
                    ss << $1.code;
                }
                if (tempVars.find($1.ret_name) != tempVars.end()) {
                    tempVars[$1.ret_name] = temp0;
                }
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | NUMBER {
                stringstream ss;
                string temp0 = make_temp();
                ss << ". " << temp0 << "\n";
                ss << "= " << temp0 << ", " << to_string($1) << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            }
            | L_PAREN expression R_PAREN {
                $$.code = strdup($2.code);
                $$.ret_name = strdup($2.ret_name);
            }
            | ident L_PAREN expressions R_PAREN {
                stringstream ss;
                string func = $1.ret_name;
                if (predefFuncs.find(func) == predefFuncs.end()) {
                    cout << "Calling undeclared function " << func.c_str() << endl;
                }
                string temp0 = make_temp();
                ss << $3.code;
                ss << ". " << temp0 << "\ncall ";
                ss << $1.ret_name;
                ss << ", " << temp0 << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(temp0.c_str());
            };

expressions:    expression {
                    stringstream ss;
                    ss << $1.code << "param " << $1.ret_name << "\n";
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                }
                | expression COMMA expressions {
                    stringstream ss;
                    ss << $1.code << "param " << $1.ret_name << "\n";
                    ss << $3.code;
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                };

vars:	    var COMMA vars {
                stringstream ss;
                ss << $1.code;
                if ($1.is_arr) {
                    ss << ".[]| ";
                } else {
                    ss << ".| ";
                }
                ss << $1.ret_name << "\n" << $3.code;
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup("");
            }
            | var {
                stringstream ss;
                ss << $1.code;
                if ($1.is_arr) {
                    ss << ".[]| ";
                } else {
                    ss << ".| ";
                }
                ss << $1.ret_name << "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup("");
            };

var:        ident {
                $$.code = strdup("");
                string ident = $1.ret_name;
                if (predefFuncs.find(ident) == predefFuncs.end() && tempVars.find(ident) == tempVars.end()) {
                    cout << "Identifier " << ident.c_str() << " is not declared" << endl;
                } else if (arrSize[ident] > 1) {
                    cout << "No index provided for array identifier " << ident.c_str() << endl;
                }
                $$.ret_name = strdup(ident.c_str());
                $$.is_arr = false;
            }
            | ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
                stringstream ss;
                string ident = $1.ret_name;
                if (predefFuncs.find(ident) == predefFuncs.end() && tempVars.find(ident) == tempVars.end()) {
                    cout << "Identifier " << ident.c_str() << " not declared." << endl;
                } else if (arrSize[ident] == 1) {
                    cout << "Provided index for non-array identifier " << ident.c_str() << endl;
                }
                ss << $1.ret_name << ", " << $3.ret_name;
                string temp = ss.str();
                $$.code = strdup($3.code);
                $$.ret_name = strdup(temp.c_str());
                $$.is_arr = true;
            };
%%

string make_temp() {
    string t = "__temp__" + to_string(temp_num);
    temp_num++;
    return t;
}

string make_label() {
    string l = "__label__" + to_string(label_num);
    label_num++;
    return l;
}

void yyerror(const char* s) {
    extern int yylineno;	// defined and maintained in lex.c
    extern char *yytext;    // defined and maintained in lex.c
    printf("%s on line %d at char %d at symbol \"%s\"\n", s, yylineno, currPos, yytext);
    exit(1);
}
