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
    bool mainFunc = false;
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

  struct E {
      bool  is_arr;
      char* ret_name;
      char* code;
  } expression;

  struct S {
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
                if (!mainFunc) {
                    cout << "Missing main function declaration" << endl;
                }
            }
            | function program  {};

function:   FUNCTION func_ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
                stringstream ss;
                ss << "func " << $2.ret_name << "\n";
                string s = $2.ret_name;
                if (s == "main") {
                    mainFunc = true;
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
                    //printf("ERROR: Continue is outside loop in function %s\n", $2.ret_name);
                }
                ss << statements << "endfunc\n";
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
                    //string temp;
                    bool ex = false;
                    while(!ex) {
                        right = parse.find("|", left);
                        ss << ". ";
                        //temp.append(". ");
                        if (right == string::npos) {
                            string ident = parse.substr(left, right);
                            if (reservedWords.find(ident) != reservedWords.end()) {
                                cout << "Identifier " << ident.c_str() << " is a reserved word." << endl;
                                //printf("Identifier %s is a reservedWords word.\n", ident.c_str());
                            }
                            if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                                cout << "Identifier " << ident.c_str() << " was previously declared" << endl;
                                //printf("Identifier %s was previously declared.\n", ident.c_str());
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
                                //printf("Identifier %s is a reservedWords word.\n", ident.c_str());
                            }
                            if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                                cout << "Identifier " << ident.c_str() << " was previously declared." << endl;
                                //printf("Identifier %s was previously declared.\n", ident.c_str());
                            } else {
                                tempVars[ident] = ident;
                                arrSize[ident] = 1;
                            }
                            ss << ident;
                            //temp.append(ident);
                            left = right + 1;
                        }
                        ss << "\n";
                        //temp.append("\n");
                    }
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                }
    | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER  {
            stringstream ss;
            //string temp;
            size_t left = 0;
            size_t right = 0;
            string parse($1.ret_name);
            bool ex = false;
            while(!ex) {
                right = parse.find("|", left);
                ss << ".[] ";
                //temp.append(".[] ");
                if (right == string::npos) {
                    string ident = parse.substr(left, right);
                    if (reservedWords.find(ident) != reservedWords.end()) {
                        cout << "Identifier name" << ident.c_str() << " is a reserved word." << endl;
                        //printf("Identifier %s's name is a reserved word.\n", ident.c_str());
                    }
                    if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                        cout << "Identifier " << ident.c_str() << " was previously declared" << endl;
                        //printf("Identifier %s is previously declared.\n", ident.c_str());
                    } else {
                        if ($5 <= 0) {
                            cout << "Declaring and array ident " << ident.c_str() << " of size less than or equal to 0." << endl;
                            //printf("Declaring array ident %s of size less than or equal to 0.\n", ident.c_str());
                        }
                        tempVars[ident] = ident;
                        arrSize[ident] = $5;
                    }
                    ss << ident;
                    //temp.append(ident);
                    ex = true;
                } else {
                    string ident = parse.substr(left, right-left);
                    if (reservedWords.find(ident) != reservedWords.end()) {
                        cout << "Identifier " << ident.c_str() << " shares a name with a reserved word" << endl;
                        //printf("Identifier %s's name is a reservedWords word.\n", ident.c_str());
                    }
                    if (predefFuncs.find(ident) != predefFuncs.end() || tempVars.find(ident) != tempVars.end()) {
                        cout << "Identifier " << ident.c_str() << " was previously declared" << endl;
                        //printf("Identifier %s is previously declared.\n", ident.c_str());
                    } else {
                        if ($5 <= 0) {
                            cout << "Declaring array ident " << ident.c_str() << " of size less than or equal to 0" << endl;
                            //printf("Declaring array ident %s of size <= 0.\n", ident.c_str());
                        }
                        tempVars[ident] = ident;
                        arrSize[ident] = $5;
                    }
                    ss << ident;
                    //temp.append(ident);
                    left = right + 1;
                }
                ss << ", " << to_string($5) << "\n";
                //temp.append(", ");
                //temp.append(to_string($5));
                //temp.append("\n");
            }
            string temp = ss.str();
            $$.code = strdup(temp.c_str());
            $$.ret_name = strdup("");
        };

func_ident:	IDENT {
                if (predefFuncs.find($1) != predefFuncs.end()) {
                    cout << "function name " << $1 << " already declared." << endl;
                    //printf("function name %s already declared.\n", $1);
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
                ss << $1.ret_name << "|" << $3.ret_name;
                string temp = ss.str();
                //string temp;
                //temp.append($1.ret_name);
                //temp.append("|");
                //temp.append($3.ret_name);
                $$.ret_name = strdup(temp.c_str());
                $$.code = strdup("");
            };

statements: statement SEMICOLON statements {
                stringstream ss;
                ss << $1.code << $3.code;
                string temp = ss.str();
                //temp.append($1.code);
                //temp.append($3.code);
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
                //string temp;
                //temp.append($1.code);
                //temp.append($3.code);
                string mid = $3.ret_name;
                if ($1.is_arr && $3.is_arr) {
                    ss << "[]= ";
                } else if ($1.is_arr) {
                    ss << "[]= ";
                } else if ($3.is_arr) {
                    ss << "= ";
                } else {
                    ss << "= ";
                }
                ss << $1.ret_name << ", " << mid << "\n";
                //temp.append($1.ret_name);
                //temp.append(", ");
                //temp.append(mid);
                //temp += "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
            | IF bool-expr THEN statements ENDIF {
                stringstream ss;
                string ifS = make_label();
                string after = make_label();
                //string temp;
                ss << $2.code;
                //temp.append($2.code);
                ss << "?:= " << ifS << ", " << $2.ret_name << "\n";
                ss << ":= " << after << "\n";
                ss << ": " << ifS << "\n";
                ss << $4.code;
                ss << ": " << after << "\n";
                //temp = temp + "?:= " + ifS + ", " + $2.ret_name + "\n"; //If true, jump to :ifS and do code from $4
                //temp = temp + ":= " + after + "\n"; //Reached if above not true, skips $4 code by jumping to l2
                //temp = temp + ": " + ifS + "\n";
                //temp.append($4.code);
                //temp = temp + ": " + after + "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
            | IF bool-expr THEN statements ELSE statements ENDIF {
                stringstream ss;
                //string temp;
                string ifS = make_label();
                string after = make_label();
                ss << $2.code;
                //temp.append($2.code);
                ss << "?:= " << ifS << ", " << $2.ret_name << "\n";
                ss << $6.code;
                ss << ":= " << after << "\n ";
                ss << ": " << ifS << "\n";
                ss << $4.code;
                ss << ": " << after << "\n";
                //temp = temp + "?:= " + ifS + ", " + $2.ret_name + "\n"; //If true, jump to :ifS and do code from $4
                //temp.append($6.code); //Reached is above not true, does $5 code
                //temp = temp + ":= " + after + "\n"; //Prevents else code from running if's code
                //temp = temp + ": " + ifS + "\n";
                //temp.append($4.code); //Reached by :ifS jump, if's code
                //temp = temp + ": " + after + "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
            | WHILE bool-expr BEGINLOOP statements ENDLOOP {
                stringstream ss;
                //string temp;
                string begin = make_label();
                string inner = make_label();
                string after = make_label();
                string code = $4.code;
                size_t pos = code.find("continue");
                while (pos != string::npos) {
                    code.replace(pos, 8, ":= "+begin);
                    pos = code.find("continue");
                }
                ss << ": " << begin << "\n";
                ss << $2.code;
                ss << "?:= " << inner << ", ";
                ss << $2.ret_name << "\n";
                ss << ":= " << after << "\n";
                ss << ": " << inner << "\n";
                ss << code;
                ss << ":= " << begin << "\n";
                ss << ": " << after << "\n";

                //temp.append(": ");
                //temp += begin + "\n"; //Defines start of while loop
                //temp.append($2.code);
                //temp += "?:= " + inner + ", "; //If true, jumps to code
                //temp.append($2.ret_name);
                //temp.append("\n");
                //temp += ":= " + after + "\n"; //If reached, jumps past while loop
                //temp += ": " + inner + "\n"; //Marks start of code
                //temp.append(code);
                //temp += ":= " + begin + "\n"; //Reached by completing code, returns to start of while loop
                //temp += ": " + after + "\n"; //Marks end of while loop
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
            }
    | DO BEGINLOOP statements ENDLOOP WHILE bool-expr {
        stringstream ss;
        //string temp;
        string begin = make_label();
        string condition = make_label();
        string code = $3.code;
        size_t pos = code.find("continue");
        while (pos != string::npos) {
            code.replace(pos, 8, ":= "+condition);
            pos = code.find("continue");
        }
        ss << ": " << begin << "\n" << code;
        ss << ": " << condition << "\n";
        ss << $6.code;
        ss << "?:= " << begin << ", ";
        ss << $6.ret_name << "\n";
        //temp.append(": ");
        //temp += begin + "\n";
        //temp.append(code);
        //temp += ": " + condition + "\n";
        //temp.append($6.code);
        //temp += "?:= " + begin + ", ";
        //temp.append($6.ret_name);
        //temp.append("\n");
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
    }
    | FOR var ASSIGN NUMBER SEMICOLON bool-expr SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {
        stringstream ss;
        //string temp;
        string dst = make_temp();
        string condition = make_label();
        string inner = make_label();
        string increment = make_label();
        string after = make_label();
        string code = $12.code;
        size_t pos = code.find("continue");
        while (pos != string::npos) {
            code.replace(pos, 8, ":= "+increment);
            pos = code.find("continue");
        }
        ss << $2.code;
        //temp.append($2.code);
        string middle = to_string($4);
        if ($2.is_arr) {
            ss << "[]= ";
            //temp += "[]= ";
        } else {
            ss << "= ";
            //temp += "= ";
        }
        ss << $2.ret_name << ", " << middle << "\n" << ": " << condition << "\n";
        ss << $6.code;
        ss << "?:= " << inner << ", ";
        ss << $6.ret_name << "\n";
        ss << ":= " << after << "\n";
        ss << ": " << inner << "\n";
        ss << code;
        ss << ": "<< increment << "\n" << $8.code << $10.code;
        //temp.append($2.ret_name);
        //temp.append(", ");
        //temp.append(middle);
        //temp += "\n";
        //temp += ": " + condition + "\n";
        //temp.append($6.code);
        //temp += "?:= " + inner + ", "; //If true, jumps to code
        //temp.append($6.ret_name);
        //temp.append("\n");
        //temp += ":= " + after + "\n"; //If reached, jumps past increment and code
        //temp += ": " + inner + "\n"; //Marks start of code
        //temp.append(code);
        //temp += ": " + increment + "\n";
        //temp.append($8.code);
        //temp.append($10.code);
        if ($8.is_arr) {
            ss << "[]= ";
            //temp += "[]= ";
        } else {
            ss << "[]= ";
            //temp += "= ";
        }
        ss << $8.ret_name << ", " << $10.ret_name << "\n";
        ss << ":= " << condition << "\n";
        ss << ": " << after << "\n";
        //temp.append($8.ret_name);
        //temp.append(", ");
        //temp.append($10.ret_name);
        //temp += "\n";
        //temp += ":= " + condition + "\n";
        //temp += ": " + after + "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
    }
    | READ vars {
        string temp;
        temp.append($2.code);
        size_t pos = temp.find("|", 0);
        while(pos != string::npos) {
            temp.replace(pos, 1, "<");
            pos = temp.find("|", pos);
        }
        $$.code = strdup(temp.c_str());
    }
    | WRITE vars {
        string temp;
        temp.append($2.code);
        size_t pos = temp.find("|", 0);
        while(pos != string::npos) {
            temp.replace(pos, 1, ">");
            pos = temp.find("|", pos);
        }
        $$.code = strdup(temp.c_str());
    }
    | CONTINUE {
        $$.code = strdup("continue\n");
    }
    | RETURN expression {
        stringstream ss;
        ss << $2.code << "ret " << $2.ret_name << "\n";
        //string temp;
        //temp.append($2.code);
        //temp.append("ret ");
        //temp.append($2.ret_name);
        //temp.append("\n");
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
    };

bool-expr:  relation-and-expr OR bool-expr {
        stringstream ss;
        //string temp;
        string dst = make_temp();
        ss << $1.code << $3.code;
        ss << ". " << dst << "\n";
        ss << "|| "<< dst << ", ";
        ss << $1.ret_name << ", " << $3.ret_name << "\n";
        //temp.append($1.code);
        //temp.append($3.code);
        //temp += ". " + dst + "\n";
        //temp += "|| " + dst + ", ";
        //temp.append($1.ret_name);
        //temp.append(", ");
        //temp.append($3.ret_name);
        //temp.append("\n");
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(dst.c_str());
    }
    | relation-and-expr {
        $$.code = strdup($1.code);
        $$.ret_name = strdup($1.ret_name);
    };

relation-and-expr: relation-expr-inv AND relation-and-expr {
        stringstream ss;
        //string temp;
        string dst = make_temp();
        ss << $1.code << $3.code;
        ss << ". " << dst << "\n";
        ss << "&& " << dst << ", ";
        ss << $1.ret_name << ", " << "$3.ret_name" << "\n";
        //temp.append($1.code);
        //temp.append($3.code);
        //temp += ". " + dst + "\n";
        //temp += "&& " + dst + ", ";
        //temp.append($1.ret_name);
        //temp.append(", ");
        //temp.append($3.ret_name);
        //temp.append("\n");
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(dst.c_str());
    }
    | relation-expr-inv {
        $$.code = strdup($1.code);
        $$.ret_name = strdup($1.ret_name);
    };

relation-expr-inv:  NOT relation-expr-inv {
        stringstream ss;
        //string temp;
        string dst = make_temp();
        ss << $2.code;
        ss << ". " << dst << "\n";
        ss << "! " <<dst << ", ";
        ss << $2.ret_name << "\n";
        //temp.append($2.code);
        //temp += ". " + dst + "\n";
        //temp += "! " + dst + ", ";
        //temp.append($2.ret_name);
        //temp.append("\n");
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(dst.c_str());
    }
    | relation-expr {
        $$.code = strdup($1.code);
        $$.ret_name = strdup($1.ret_name);
    }

relation-expr:  expression comp expression {
        stringstream ss;
        string dst = make_temp();
        //string temp;
        ss << $1.code << $3.code;
        ss << ". " << dst << "\n" << $2.ret_name << dst << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
        //temp.append($1.code);
        //temp.append($3.code);
        //temp = temp + ". " + dst + "\n" + $2.ret_name + dst + ", " + $1.ret_name + ", " + $3.ret_name + "\n";
        string temp = ss.str();
        $$.code = strdup(temp.c_str());
        $$.ret_name = strdup(dst.c_str());
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
                //string temp;
                string dst = make_temp();
                ss << $1.code << $3.code;
                ss << ". " << dst << "\n";
                ss << "+ " << dst << ", ";
                ss << $1.ret_name << ", " << $3.ret_name << "\n";

                //temp.append($1.code);
                //temp.append($3.code);
                //temp += ". " + dst + "\n";
                //temp += "+ " + dst + ", ";
                //temp.append($1.ret_name);
                //temp += ", ";
                //temp.append($3.ret_name);
                //temp += "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            }
            | multiplicative-expr SUB expression {
                stringstream ss;
                //string temp;
                string dst = make_temp();
                ss << $1.code << $3.code;
                ss << ". " << dst << "\n";
                ss << "- " << dst << ", ";
                ss << $1.ret_name << ", " << $3.ret_name << "\n";
                //temp.append($1.code);
                //temp.append($3.code);
                //temp += ". " + dst + "\n";
                //temp += "- " + dst + ", ";
                //temp.append($1.ret_name);
                //temp += ", ";
                //temp.append($3.ret_name);
                //temp += "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            }
            | multiplicative-expr {
                $$.code = strdup($1.code);
                $$.ret_name = strdup($1.ret_name);
            };

multiplicative-expr: term MULT multiplicative-expr {
            stringstream ss;
            //string temp;
            string dst = make_temp();
            ss << $1.code << $3.code << ". " << dst << "\n";
            ss << "* " << dst << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
            //temp.append($1.code);
            //temp.append($3.code);
            //temp.append(". ");
            //temp.append(dst);
            //temp.append("\n");
            //temp += "* " + dst + ", ";
            //temp.append($1.ret_name);
            //temp += ", ";
            //temp.append($3.ret_name);
            //temp += "\n";
            string temp = ss.str();
            $$.code = strdup(temp.c_str());
            $$.ret_name = strdup(dst.c_str());
        }
        | term DIV multiplicative-expr {
            stringstream ss;
            //string temp;
            string dst = make_temp();
            ss << $1.code << $3.code << ". " << dst << "\n";
            ss << "/ " << dst << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
            //temp.append($1.code);
            //temp.append($3.code);
            //temp.append(". ");
            //temp.append(dst);
            //temp.append("\n");
            //temp += "/ " + dst + ", ";
            //temp.append($1.ret_name);
            //temp += ", ";
            //temp.append($3.ret_name);
            //temp += "\n";
            string temp = ss.str();
            $$.code = strdup(temp.c_str());
            $$.ret_name = strdup(dst.c_str());
        }
        | term MOD multiplicative-expr {
            stringstream ss;
            //string temp;
            string dst = make_temp();
            ss << $1.code << $3.code << ". " << dst << "\n";
            ss << "% t" << dst << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
            //temp.append($1.code);
            //temp.append($3.code);
            //temp.append(". ");
            //temp.append(dst);
            //temp.append("\n");
            //temp += "% t" + dst + ", ";
            //temp.append($1.ret_name);
            //temp += ", ";
            //temp.append($3.ret_name);
            //temp += "\n";
            string temp = ss.str();
            $$.code = strdup(temp.c_str());
            $$.ret_name = strdup(dst.c_str());
        }
        | term {
            $$.code = strdup($1.code);
            $$.ret_name = strdup($1.ret_name);
        };

term:       SUB var {
                stringstream ss;
                string dst = make_temp();
                //string temp;
                if ($2.is_arr) {
                    ss << $2.code << ". " << dst << "\n";
                    ss << "=[] " << dst << ", " << $2.ret_name << "\n";
                    //temp.append($2.code);
                    //temp.append(". ");
                    //temp.append(dst);
                    //temp.append("\n");
                    //temp += "=[] " + dst + ", ";
                    //temp.append($2.ret_name);
                    //temp.append("\n");
                } else {
                    ss << ". " << dst << "\n";
                    ss << "= " << dst << ", " << $2.ret_name << "\n";
                    ss << $2.code;
                    //temp.append(". ");
                    //temp.append(dst);
                    //temp.append("\n");
                    //temp = temp + "= " + dst + ", ";
                    //temp.append($2.ret_name);
                    //temp.append("\n");
                    //temp.append($2.code);
                }
                if (tempVars.find($2.ret_name) != tempVars.end()) {
                    tempVars[$2.ret_name] = dst;
                }
                ss << "* " << dst << ", " << dst << "-1\n";
                //temp += "* " + dst + ", " + dst + ", -1\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            }
            | SUB NUMBER {
                stringstream ss;
                string dst = make_temp();
                //string temp;
                ss << ". " << dst << "\n";
                ss << "= " << dst << ", -" << to_string($2) << "\n";
                //temp.append(". ");
                //temp.append(dst);
                //temp.append("\n");
                //temp = temp + "= " + dst + ", -" + to_string($2) + "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            }
            | SUB L_PAREN expression R_PAREN {
                stringstream ss;
                //string temp;
                ss << $3.code << "* " << $3.ret_name << ", -1\n";
                //temp.append($3.code);
                //temp.append("* ");
                //temp.append($3.ret_name);
                //temp.append(", ");
                //temp.append($3.ret_name);
                //temp.append(", -1\n");
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup($3.ret_name);
            }
            | var {
                stringstream ss;
                string dst = make_temp();
                //string temp;
                if ($1.is_arr) {
                    ss << $1.code << ". " << dst << "\n";
                    ss << "=[] " << dst << ", " << $1.ret_name << "\n";
                    //temp.append($1.code);
                    //temp.append(". ");
                    //temp.append(dst);
                    //temp.append("\n");
                    //temp += "=[] " + dst + ", ";
                    //temp.append($1.ret_name);
                    //temp.append("\n");
                } else {
                    ss << ". " << dst << "\n";
                    ss << "= " << dst << ", " << $1.ret_name << "\n";
                    ss << $1.code;
                    //temp.append(". ");
                    //temp.append(dst);
                    //temp.append("\n");
                    //temp = temp + "= " + dst + ", ";
                    //temp.append($1.ret_name);
                    //temp.append("\n");
                    //temp.append($1.code);
                }
                if (tempVars.find($1.ret_name) != tempVars.end()) {
                    tempVars[$1.ret_name] = dst;
                }
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            }
            | NUMBER {
                stringstream ss;
                string dst = make_temp();
                //string temp;
                ss << ". " << dst << "\n";
                ss << "= " << dst << ", " << to_string($1) << "\n";
                //temp.append(". ");
                //temp.append(dst);
                //temp.append("\n");
                //temp = temp + "= " + dst + ", " + to_string($1) + "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            }
            | L_PAREN expression R_PAREN {
                $$.code = strdup($2.code);
                $$.ret_name = strdup($2.ret_name);
            }
            | ident L_PAREN expressions R_PAREN {
                stringstream ss;
                //string temp;
                string func = $1.ret_name;
                if (predefFuncs.find(func) == predefFuncs.end()) {
                    cout << "Calling undeclared function " << func.c_str() << endl;
                    //printf("Calling undeclared function %s.\n", func.c_str());
                }
                string dst = make_temp();
                ss << $3.code;
                ss << ". " << dst << "\ncall ";
                ss << $1.ret_name;
                ss << ", " << dst << "\n";

                //temp.append($3.code);
                //temp += ". " + dst + "\ncall ";
                //temp.append($1.ret_name);
                //temp += ", " + dst + "\n";
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup(dst.c_str());
            };

expressions:    expression {
                    stringstream ss;
                    //string temp;
                    ss << $1.code << "param " << $1.ret_name << "\n";
                    //temp.append($1.code);
                    //temp.append("param ");
                    //temp.append($1.ret_name);
                    //temp.append("\n");
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                }
                | expression COMMA expressions {
                    stringstream ss;
                    //string temp;
                    ss << $1.code << "param " << $1.ret_name << "\n";
                    ss << $3.code;
                    //temp.append($1.code);
                    //temp.append("param ");
                    //temp.append($1.ret_name);
                    //temp.append("\n");
                    //temp.append($3.code);
                    string temp = ss.str();
                    $$.code = strdup(temp.c_str());
                    $$.ret_name = strdup("");
                };

vars:	    var COMMA vars {
                stringstream ss;
                //string temp;
                ss << $1.code;
                //temp.append($1.code);
                if ($1.is_arr) {
                    ss << ".[]| ";
                    //temp.append(".[]| ");
                } else {
                    ss << ".| ";
                    //temp.append(".| ");
                }
                ss << $1.ret_name << "\n" << $3.code;
                //temp.append($1.ret_name);
                //temp.append("\n");
                //temp.append($3.code);
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup("");
            }
            | var {
                stringstream ss;
                //string temp;
                ss << $1.code;
                //temp.append($1.code);
                if ($1.is_arr) {
                    ss << ".[]| ";
                    //temp.append(".[]| ");
                } else {
                    ss << ".| ";
                    //temp.append(".| ");
                }
                ss << $1.ret_name << "\n";
                //temp.append($1.ret_name);
                //temp.append("\n");
                string temp = ss.str();
                $$.code = strdup(temp.c_str());
                $$.ret_name = strdup("");
            };

var:        ident {
                $$.code = strdup("");
                string ident = $1.ret_name;
                if (predefFuncs.find(ident) == predefFuncs.end() && tempVars.find(ident) == tempVars.end()) {
                    cout << "Identifier " << ident.c_str() << " is not declared" << endl;
                    //printf("Identifier %s is not declared.\n", ident.c_str());
                } else if (arrSize[ident] > 1) {
                    cout << "No index provided for array identifier " << ident.c_str() << endl;
                    //printf("Did not provide index for array Identifier %s.\n", ident.c_str());
                }
                $$.ret_name = strdup(ident.c_str());
                $$.is_arr = false;
            }
            | ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
                stringstream ss;
                //string temp;
                string ident = $1.ret_name;
                if (predefFuncs.find(ident) == predefFuncs.end() && tempVars.find(ident) == tempVars.end()) {
                    cout << "Identifier " << ident.c_str() << " not declared." << endl;
                    //printf("Identifier %s is not declared.\n", ident.c_str());
                } else if (arrSize[ident] == 1) {
                    cout << "Provided index for non-array identifier " << ident.c_str() << endl;
                    //printf("Provided index for non-array Identifier %s.\n", ident.c_str());
                }
                ss << $1.ret_name << ", " << $3.ret_name;
                //temp.append($1.ret_name);
                //temp.append(", ");
                //temp.append($3.ret_name);
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
