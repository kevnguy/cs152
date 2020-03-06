/* MINI-L Parser for CS152 Part 2*/
%code requires{
    #include <string>
    using namespace std;
    struct nonTerm {
        string code;
        string ret_name;
    }
}

%{
    #include <iostream>
    #include <string>
    using namespace std;
    int yyerror(string s);
    int yyerror(char *s);
    int yylex(void);
    extern FILE* yyin;
    struct nonTerm {
        string code;
        string ret_name;
    }
    //function for label (just return string "label n")
    //same for tempvar^
    //may need struct for operators
%}


%start prog_start

%token FUNCTION
%token SEMICOLON COLON COMMA
%token<id> IDENT
%token<num> NUMBER
%token BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY
%token INTEGER ARRAY
%token L_SQUARE_BRACKET R_SQUARE_BRACKET
%token IF THEN ENDIF ELSE WHILE OF
%token BEGINLOOP ENDLOOP
%token READ WRITE CONTINUE RETURN
%token OR AND
%token GT LT NEQ LTE GTE
%token L_PAREN R_PAREN
%token TRUE FALSE
%token FOR DO EQ
%token END_BODY NOT
%left ADD SUB DIV MULT MOD NEG ASSIGN

//attach nonTerm type to all nonterminals like below
%type<nterm> prog_start
%type<nterm> functions
%type<nterm> function
%type<nterm> declaration
%type<nterm> declarations
%type<nterm> statement
%type<nterm> statements
%type<nterm> bool_exp
%type<nterm> relation_and_exp
%type<nterm> relation_exp
%type<nterm> nots
%type<nterm> comp
%type<nterm> expression
%type<nterm> multiplicative_expression
%type<nterm> term
%type<nterm> term_num
%type<nterm> vars
%type<nterm> var
%type<nterm> identifiers
%type<nterm> identifier
%type<nterm> number
%type<nterm> expressions

%union {
    int num;
    char* id;
    nonTerm* nterm;
}

%%
//Actual output done in prog_start
prog_start:         functions {};
functions:          function functions {}
                    | /*epsilon*/ {};
function:           FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY{
                        stringstream ss;
                        ss << "func" << $2.
                    };
declaration:        identifiers COLON INTEGER { //done
                        stringstream ss;
                        string hold;
                        string temp = $1.code;
                        stringstream ids(temp);
                        while(ids >> hold) {
                            ss << ". " << hold << "\n";
                            ss << "= " << hold << ", " << $3 << "\n";
                        }
                    }
                    | identifiers COLON ARRAY L_SQUARE_BRACKET number R_SQUARE_BRACKET OF INTEGER { //done
                        stringstream ss;
                        string hold;
                        string temp = $1.code;
                        stringstream ids(temp);
                        while(ids >> hold) {
                            ss << ".[] " << hold << ", " << $4.code << "\n";
                        }
                    };
declarations:       declaration SEMICOLON declarations {}
                    | /*epsilon*/ {};
statement:          var ASSIGN expression {}
                    | IF bool_exp THEN statements ENDIF {}
                    | IF bool_exp THEN statements ELSE statements ENDIF {}
                    | WHILE bool_exp BEGINLOOP statements ENDLOOP {}
                    | DO BEGINLOOP statements ENDLOOP WHILE bool_exp {}
                    | FOR var ASSIGN number SEMICOLON bool_exp SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {}
                    | READ vars {}
                    | WRITE vars {}
                    | CONTINUE {}
                    | RETURN expression {};
statements:         statement SEMICOLON statements {}
                    | /*epsilon*/ {};
bool_exp:           relation_and_exp OR relation_and_exp {}
                    | relation_and_exp {};
relation_and_exp:   relation_exp AND relation_exp {}
                    | relation_exp {};
relation_exp:       nots expression comp expression {
                        string temp_var1 = make_temp();
                        string temp_var2 = make_temp();
                        stringstream ss;
                        ss << ". " << temp_var1 << "\n";
                        ss << $3.ret_name << temp_var1 << ", " << $2.code << ", " << $4.code << "\n";
                        ss << ". " << temp_var2 << "\n";
                        ss << "! " << temp_var2 << ", " << temp_var1 << "\n";
                        $$.code = ss.str();
                    }
                    | nots TRUE {
                        $$.code = //empty?
                        $$.ret_name = "1";
                    }
                    | nots FALSE {
                        $$.code = //empty?
                        $$.ret_name = "0";
                    }
                    | nots L_PAREN bool_exp R_PAREN {
                        $$.code = $2.code;
                        $$.ret_name = $2.ret_name;
                    };
nots:               NOT {
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << "! " << temp_var << ", ";
                        $$.code = ss;
                        $$.ret_name = "! ";
                    };
                    | /*epsilon*/ {};
comp:               EQ {
                        $$.ret_name = "== ";
                    }
                    | NEQ {
                        $$.ret_name = "!= ";
                    }
                    | LT {
                        $$.ret_name = "< ";
                    }
                    | GT {
                        $$.ret_name = "> ";
                    }
                    | LTE {
                        $$.ret_name = "<= ";
                    }
                    | GTE {
                        $$.ret_name = ">= ";
                    };
expression:         multiplicative_expression {
                        $$.code = $1.code;
                        $$.ret_name = $1.ret_name;
                    }
                    | multiplicative_expression ADD multiplicative_expression {
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << $1.code << $3.code;
                        ss << ". " << temp_var << "\n"; //declare destination
                        ss << "+ " << temp_var << ", " << $1.ret_name << ", " << $3.ret_name << "\n";
                        $$.code = ss.str();
                        $$.ret_name = temp_var;
                    }
                    | multiplicative_expression SUB multiplicative_expression {
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << $1.code << $3.code;
                        ss << ". " << temp_var << "\n";
                        ss << "- " << temp_var << ", " << "$1.ret_name" << ", " << $3.ret_name << "\n";
                        $$.code = ss.str();
                        $$.ret_name = temp_var;
                    };
multiplicative_expression: term {
                        $$.code = $1.code;
                        $$.ret_name = $1.ret_name;
                    }
                    | term MULT term {
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << $1.code << $3.code;
                        ss << ". " << tempvar << "\n";
                        ss << "* " << tempvar << "," << $1.ret_name << "," << $3.ret_name << "\n";
                        $$.code = ss.str();
                        $$.ret_name = temp_var;
                    }
                    | term DIV term {
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << $1.code << $3.code;
                        ss << ". " << tempvar << "\n";
                        ss << "/ " << tempvar << "," << $1.ret_name << "," << $3.ret_name << "\n";
                        $$.code = ss.str();
                        $$.ret_name = temp_var;
                    }
                    | term MOD term {
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << $1.code << $3.code;
                        ss << ". " << tempvar << "\n";
                        ss << "% " << tempvar << "," << $1.ret_name << "," << $3.ret_name << "\n";
                        $$.code = ss.str();
                        $$.ret_name = temp_var;
                    };
term:               NEG term_num {}
                    | term_num {}
                    | identifier L_PAREN expressions R_PAREN { //possible check for undeclared
                        string temp_var = make_temp();
                        stringstream ss;
                        ss << $3.code;
                        ss << ". " << tempvar << "\n";
                        ss <<

                    };
term_num:           var {}
                    | number {}
                    | L_PAREN expression R_PAREN {
                        $$.code = $2.code;
                        $$.ret_name = $2.ret_name;
                    }
                    | var COMMA vars {};
vars:               var {}
                    | var COMMA vars {};
var:                identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {}
                    | identifier {
                        $$.code = //empty?
                        $$.ret_name = $1.ret_name;
                    };
identifiers:        identifier COMMA identifiers { //done
                        stringstream ss;
                        ss << $1.ret_name << " " << $3.code;
                        $$.code = ss;
                    }
                    | identifier { //done
                        $$.ret_name = $1.ret_name;
                    };
identifier:         IDENT { //done
                        $$.ret_name = $1;
                    };
number:             NUMBER {
                        $$.code = to_string($1);
                    };
expressions:        expression COMMA expressions {
                        stringstream ss;
                        ss << $1.code << "param " << $1.ret_name << "\n";
                        ss << "$3.code";
                        $$.code = ss.str();
                        $$ret_name = //empty?
                    }
                    | expression {
                        stringstream ss;
                        ss << $1.code << "param " << $1.ret_name << "\n";
                        $$.code = ss.str();
                        $$.ret_name = //empty?
                    }
                    | /*epsilon*/ {
                        $$.code = //empty?
                        $$.ret_name = //empty?
                    };

%%

string make_temp() {
    static int num = 0;
    string temp = "__temp" + to_string(num++) + "__";
    return temp;
}

string make_label() {
    static int num = 0;
    string label = "__label" + to_string(num++) + "__";
    return label;
}

int yyerror (string s) {
    extern int currLine, currPos;
    extern char *yytext;
    cout << s << ": parsing error at line: " << currLine << ", column: " << currPos << endl
            << "Unexpected symbol `" << yytext << "` encountered." << endl;
    exit(1);
}

int yyerror (char* s) {
    return yyerror(string(s));
}

/*int main(int argc, char ** argv)
{
   if(argc >= 2)
   {
      yyin = fopen(argv[1], "r");
      if(yyin == NULL)
      {
         yyin = stdin;
      }
   }
   else
   {
      yyin = stdin;
   }

   yyparse();
}*/
