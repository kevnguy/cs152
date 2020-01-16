%{   
   int currLine = 1, currPos = 1, intCount = 0, opCount = 0, pCount = 0, eqCount = 0;
%}
   
%%

"-"            {printf("MINUS\n"); currPos += yyleng; ++opCount;}
"+"            {printf("PLUS\n"); currPos += yyleng; ++opCount;}
"*"            {printf("MULT\n"); currPos += yyleng; ++opCount;}
"/"            {printf("DIV\n"); currPos += yyleng; ++opCount;}
"="            {printf("EQUAL\n"); currPos += yyleng; ++eqCount;}
"("            {printf("L_PAREN\n"); currPos += yyleng; ++pCount;}
")"            {printf("R_PAREN\n"); currPos += yyleng; ++pCount;}

[0-9]+       {printf("NUMBER %s\n", yytext); currPos += yyleng; ++intCount;}

[ \t]+         {/* ignore spaces */ currPos += yyleng;}

"\n"           {currLine++; currPos = 1;}

.              {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%

int main(int argc, char ** argv)
{
   yyin = fopen(argv[1], "r");
   yylex();
   fclose(yyin);
   printf("\nNumber of integers: %d\n", intCount);
   printf("Number of parantheses: %d\n", pCount); 
   printf("Number of equal signs: %d\n", eqCount);
   printf("Number of operators: %d\n", opCount);
}
