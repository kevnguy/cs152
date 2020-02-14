/* MINI-L Parser*/

%{
    #include <string>
    //include mini_l.l?
    int yyerror(char *s);
    int yylex(void);
}

%start input

%%

prog_start:                 functions {cout << "prog_start -> functions"}
functions:                  function functions
                            | /*empty*/
function:                   FUNCTION IDENT SEMICOLON BEGIN
