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

prog_start:         functions {};
functions:          function functions {}
                    | /*epsilon*/ {};
function:           FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY{};
declaration:        identifiers COLON INTEGER {}
                    | identifiers COLON ARRAY L_SQUARE_BRACKET number R_SQUARE_BRACKET OF INTEGER {};
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
relation_exp:       nots expression comp expression {}
                    | TRUE {}
                    | FALSE {}
                    | L_PAREN bool_exp R_PAREN {};
nots:               NOT {};
                    | /*epsilon*/ {};
comp:               EQ {}
                    | NEQ {}
                    | LT {}
                    | GT {}
                    | LTE {}
                    | GTE {};
expression:         multiplicative_expression {}
                    | multiplicative_expression ADD multiplicative_expression {}
                    | multiplicative_expression SUB multiplicative_expression {};
multiplicative_expression: term {}
                    | term MULT term {}
                    | term DIV term {}
                    | term MOD term {};
term:               NEG term_num {}
                    | term_num {}
                    | identifier L_PAREN expressions R_PAREN {};
term_num:           var {}
                    | number {}
                    | L_PAREN expression R_PAREN {}
                    | var COMMA vars {;
var:                identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET" << endl;}
                    | identifier {};
identifiers:        identifier COMMA identifiers {}
                    | identifier {};
identifier:         IDENT {};
number:             NUMBER {};
expressions:        expression COMMA expressions {}
                    | expression {}
                    | {};

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
