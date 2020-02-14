/* MINI-L Parser*/

%{
    #include <string>
    //include mini_l.l?
    int yyerror(char *s);
    int yylex(void);
}

%start input

%%
