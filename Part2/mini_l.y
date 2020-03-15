/* MINI-L Parser for CS152 Part 2*/
%{
    #include <iostream>
    #include <string>
    using namespace std;
    int yyerror(string s);
    int yyerror(char *s);
    int yylex(void);
    extern FILE* yyin;
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

%union {
    int num;
    char* id;
}

%%

prog_start:         functions {cout << "prog_start -> functions" << endl;};
functions:          function functions {cout << "functions -> function functions" << endl;}
                    | /*epsilon*/ {cout << "functions -> epsilon" << endl;};
function:           FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY{cout << "function -> FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY" << endl;};
declaration:        identifiers COLON INTEGER {cout << "declaration -> identifiers COLON INTEGER" << endl;}
                    | identifiers COLON ARRAY L_SQUARE_BRACKET number R_SQUARE_BRACKET OF INTEGER {cout << "declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET number R_SQUARE_BRACKET OF INTEGER" << endl;};
declarations:       declaration SEMICOLON declarations {cout << "declarations -> declaration SEMICOLON declarations" << endl;}
                    | /*epsilon*/ {cout << "declarations -> epsilon" << endl;};
statement:          var ASSIGN expression {cout << "statement -> var ASSIGN expression" << endl;}
                    | IF bool_exp THEN statements ENDIF {cout << "statement -> IF bool_exp THEN statements ENDIF" << endl;}
                    | IF bool_exp THEN statements ELSE statements ENDIF {cout << "statement -> IF bool_exp THEN statements ELSE statements ENDIF" << endl;}
                    | WHILE bool_exp BEGINLOOP statements ENDLOOP {cout << "statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP" << endl;}
                    | DO BEGINLOOP statements ENDLOOP WHILE bool_exp {cout << "statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp" << endl;}
                    | FOR var ASSIGN number SEMICOLON bool_exp SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {cout << "statement -> FOR var ASSIGN number SEMICOLON bool_exp SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP" << endl;}
                    | READ vars {cout << "statement -> READ vars" << endl;}
                    | WRITE vars {cout << "statement -> WRITE vars" << endl;}
                    | CONTINUE {cout << "statement -> CONTINUE" << endl;}
                    | RETURN expression {cout << "statement -> RETURN expression" << endl;};
statements:         statement SEMICOLON statements {cout << "statements -> statement SEMICOLON statements" << endl;}
                    | /*epsilon*/ {cout << "statements -> epsilon" << endl;};
bool_exp:           relation_and_exp OR relation_and_exp {cout << "bool_exp -> relation_and_exp OR relation_and_exp" << endl;}
                    | relation_and_exp {cout << "bool_exp -> relation_and_exp" << endl;};
relation_and_exp:   relation_exp AND relation_exp {cout << "relation_and_exp -> relation_exp AND relation_exp" << endl;}
                    | relation_exp {cout << "relation_and_exp -> relation_exp" << endl;};
relation_exp:       nots expression comp expression {cout << "relation_exp -> nots expression comp expression" << endl;}
                    | nots TRUE {cout << "relation_exp -> nots TRUE" << endl;}
                    | nots FALSE {cout << "relation_exp -> nots FALSE" << endl;}
                    | nots L_PAREN bool_exp R_PAREN {cout << "relation_exp -> nots L_PAREN bool_exp R_PAREN" << endl;}
                    | expression comp expression {cout << "relation_exp -> nots expression comp expression" << endl;}
                    | TRUE {cout << "relation_exp -> TRUE" << endl;}
                    | FALSE {cout << "relation_exp -> FALSE" << endl;}
                    | L_PAREN bool_exp R_PAREN {cout << "relation_exp -> L_PAREN bool_exp R_PAREN" << endl;};
nots:               NOT {cout << "nots -> NOT" << endl;};
comp:               EQ {cout << "comp -> EQ" << endl;}
                    | NEQ {cout << "comp -> NEQ" << endl;}
                    | LT {cout << "comp -> LT" << endl;}
                    | GT {cout << "comp -> GT" << endl;}
                    | LTE {cout << "comp -> LTE" << endl;}
                    | GTE {cout << "comp -> GTE" << endl;};
expression:         multiplicative_expression {cout << "expression -> multiplicative_expression" << endl;}
                    | multiplicative_expression ADD expression {cout << "expression -> multiplicative_expression ADD multiplicative_expression" << endl;}
                    | multiplicative_expression SUB expression {cout << "expression -> multiplicative_expression SUB multiplicative_expression" << endl;};
multiplicative_expression: term {cout << "multiplicative_expression -> term" << endl;}
                    | term MULT term {cout << "multiplicative_expression -> term MULT term" << endl;}
                    | term DIV term {cout << "multiplicative_expression -> term DIV term" << endl;}
                    | term MOD term {cout << "multiplicative_expression -> term MOD term" << endl;};
term:               NEG term_num {cout << "term -> NEG term_num" << endl;}
                    | term_num {cout << "term -> term_num" << endl;}
                    | identifier L_PAREN expressions R_PAREN {cout << "term -> identifier L_PAREN expressions R_PAREN" << endl;}
                    | identifier L_PAREN R_PAREN {cout << "term -> identifier L_PAREN R_PAREN" << endl;};
term_num:           var {cout << "term_num -> var" << endl;}
                    | number {cout << "term_num -> number" << endl;}
                    | L_PAREN expression R_PAREN {cout << "term_num -> L_PAREN expression R_PAREN" << endl;};
vars:               var {cout << "vars -> var" << endl;}
                    | var COMMA vars {cout << "vars -> var COMMA vars" << endl;};
var:                identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET" << endl;}
                    | identifier {cout << "var -> identifier" << endl;};
identifiers:        identifier COMMA identifiers {cout << "identifiers -> identifier COMMA identifiers" << endl;}
                    | identifier {cout << "identifiers -> identifier " << endl;};
identifier:         IDENT {cout << "identifier -> IDENT " << $1 << endl;};
number:             NUMBER {cout << "number -> NUMBER " << $1 << endl;};
expressions:        expression COMMA expressions {cout << "expressions -> expression COMMA expressions" << endl;}
                    | expression {cout << "expressions -> expression" << endl;};

%%

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
