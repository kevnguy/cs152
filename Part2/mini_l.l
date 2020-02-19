%{
   #include <unordered_map>
   #include <string>
   #include "mini_l.tab.h"

   using namespace std;
   int currLine = 1, currPos = 1, i = 0;
   string temp;
   unordered_map<string, yytokentype> reservedWords = {
      {"function", FUNCTION},
      {"beginparams", BEGIN_PARAMS},
      {"endparams", END_PARAMS},
      {"beginlocals", BEGIN_LOCALS},
      {"endlocals", END_LOCALS},
      {"beginbody", BEGIN_BODY},
      {"endbody", END_BODY},
      {"integer", INTEGER},
      {"array", ARRAY},
      {"of", OF},
      {"if", IF},
      {"then", THEN},
      {"endif", ENDIF},
      {"else", ELSE},
      {"while", WHILE},
      {"do", DO},
      {"for", FOR},
      {"beginloop", BEGINLOOP},
      {"endloop", ENDLOOP},
      {"continue", CONTINUE},
      {"read", READ},
      {"write", WRITE},
      {"and", AND},
      {"or", OR},
      {"not", NOT},
      {"true", TRUE},
      {"false", FALSE},
      {"return", RETURN}
   };
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
UNDERSCORE [_]
COMMENT [#]

%%
"-"            {currPos += yyleng; return SUB;}
"+"            {currPos += yyleng; return ADD;}
"*"            {currPos += yyleng; return MULT;}
"/"            {currPos += yyleng; return DIV;}
"%"            {currPos += yyleng; return MOD;}

"=="           {currPos += yyleng; return EQ;}
"<>"           {currPos += yyleng; return NEQ;}
"<"            {currPos += yyleng; return LT;}
">"            {currPos += yyleng; return GT;}
"<="           {currPos += yyleng; return LTE;}
">="           {currPos += yyleng; return GTE;}

";"            {currPos += yyleng; return SEMICOLON;}
":"            {currPos += yyleng; return COLON;}
","            {currPos += yyleng; return COMMA;}
"("            {currPos += yyleng; return L_PAREN;}
")"            {currPos += yyleng; return R_PAREN;}
"["            {currPos += yyleng; return L_SQUARE_BRACKET;}
"]"            {currPos += yyleng; return R_SQUARE_BRACKET;}
":="           {currPos += yyleng; return ASSIGN;}


{DIGIT}+       {yylval.num = stoi(yytext); currPos += yyleng; return NUMBER;}

{LETTER}({LETTER}|{DIGIT})* {
   currPos += yyleng;
   if(reservedWords.find(yytext) == reservedWords.end()) {
      yylval.id = yytext;
      return IDENT;
   }
   else {
      return reservedWords[yytext];
   }
}

[ \t]+         {/* ignore spaces */ currPos += yyleng;}

{COMMENT}{COMMENT}({LETTER}|{DIGIT}|{UNDERSCORE}|{COMMENT}|[\t]|[ ])* {currPos = 1; currLine++;}

"\n"           {currLine++; currPos = 1;}

{UNDERSCORE}({LETTER}|{DIGIT})* {
   {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); exit(0);}
}

({LETTER}|{DIGIT})*{UNDERSCORE} {
   {printf("Error at line %d, column %d: identifier \"%s\" can not end with an underscore\n", currLine, currPos, yytext); exit(0);}
}

{DIGIT}+{LETTER}({LETTER}|{DIGIT})* {
   {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); exit(0);}
}

.              {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%

int main(int argc, char ** argv)
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
}
