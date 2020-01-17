%{ 
   #include <unordered_map>
   #include <string>
   using namespace std;  
   int currLine = 1, currPos = 1, i = 0;
   string temp;
   unordered_map<string, string> reservedWords = {
      {"function", "FUNCTION"},
      {"beginparams", "BEGIN_PARAMS"},
   };
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
   
%%

"-"            {printf("MINUS\n"); currPos += yyleng;}
"+"            {printf("PLUS\n"); currPos += yyleng;}
"*"            {printf("MULT\n"); currPos += yyleng;}
"/"            {printf("DIV\n"); currPos += yyleng;}
"="            {printf("EQUAL\n"); currPos += yyleng;}
"("            {printf("L_PAREN\n"); currPos += yyleng;}
")"            {printf("R_PAREN\n"); currPos += yyleng;}

{DIGIT}+       {printf("NUMBER %s\n", yytext); currPos += yyleng;}

{LETTER}({LETTER}|{DIGIT})* {
   if(reservedWords.find(yytext) == reservedWords.end()) {
      printf("IDENT %s\n", yytext);
   }
   else {
      temp = reservedWords[yytext];
      printf("%s:\n", temp.c_str());
   }
   currPos += yyleng;
}

[ \t]+         {/* ignore spaces */ currPos += yyleng;}

"\n"           {currLine++; currPos = 1;}

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