%{
   #include <unordered_map>
   #include <string>
   using namespace std;
   int currLine = 1, currPos = 1, i = 0;
   string temp;
   unordered_map<string, string> reservedWords = {
      {"function", "FUNCTION"},
      {"beginparams", "BEGIN_PARAMS"},
      {"endparams", "END_PARAMS"},
      {"beginlocals", "BEGIN_LOCALS"},
      {"endlocals", "END_LOCALS"},
      {"beginbody", "BEGIN_BODY"},
      {"endbody", "END_BODY"},
      {"integer", "INTEGER"},
      {"array", "ARRAY"},
      {"of", "OF"},
      {"if", "IF"},
      {"then", "THEN"},
      {"endif", "ENDIF"},
      {"else", "ELSE"},
      {"while", "WHILE"},
      {"do", "DO"},
      {"for", "FOR"},
      {"beginloop", "BEGINLOOP"},
      {"endloop", "ENDLOOP"},
      {"continue", "CONTINUE"},
      {"read", "READ"},
      {"write", "WRITE"},
      {"and", "AND"},
      {"or", "OR"},
      {"not", "NOT"},
      {"true", "TRUE"},
      {"false", "FALSE"},
      {"return", "RETURN"}
   };
   unordered_map<string, string> arithmeticOp = {
      {"-", "MINUS"},
      {"+", "PLUS"},
      {"*", "MULT"},
      {"/", "DIV"},
      {"=", "EQUAL"}
   };
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
UNDERSCORE [_]
COMMENT [#]

%%
"-"            {printf("SUB\n"); currPos += yyleng;}
"+"            {printf("ADD\n"); currPos += yyleng;}
"*"            {printf("MULT\n"); currPos += yyleng;}
"/"            {printf("DIV\n"); currPos += yyleng;}
"%"            {printf("MOD\n"); currPos += yyleng;}

"=="           {printf("EQ\n"); currPos += yyleng;}
"<>"           {printf("NEQ\n"); currPos += yyleng;}
"<"            {printf("LT\n"); currPos += yyleng;}
">"            {printf("GT\n"); currPos += yyleng;}
"<="           {printf("LTE\n"); currPos += yyleng;}
">="           {printf("GTE\n"); currPos += yyleng;}

";"            {printf("SEMICOLON\n"); currPos += yyleng;}
":"            {printf("COLON\n"); currPos += yyleng;}
","            {printf("COMMA\n"); currPos += yyleng;}
"("            {printf("L_PAREN\n"); currPos += yyleng;}
")"            {printf("R_PAREN\n"); currPos += yyleng;}
"["            {printf("L_SQUARE_BRACKET\n"); currPos += yyleng;}
"]"            {printf("R_SQUARE_BRACKET\n"); currPos += yyleng;}
":="           {printf("ASSIGN\n"); currPos += yyleng;}


{DIGIT}+       {printf("NUMBER %s\n", yytext); currPos += yyleng;}

{LETTER}({LETTER}|{DIGIT})* {
   if(reservedWords.find(yytext) == reservedWords.end()) {
      printf("IDENT %s\n", yytext);
   }
   else {
      temp = reservedWords[yytext];
      printf("%s\n", temp.c_str());
   }
   currPos += yyleng;
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

   yylex();
}
