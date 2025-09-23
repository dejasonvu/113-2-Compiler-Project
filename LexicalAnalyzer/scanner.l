/* Definition section */
%{
   #include <stdio.h>
   #include <stdlib.h>
   #include <string.h>

   #define YY_NO_UNPUT
   #define YY_NO_INPUT
   #define print_token(token) \
       printf("%-8s \t %s\n", strcmp(token, "NEWLINE")? yytext: "", token)

   int line_num = 0;
   int comment_num = 0;
   int last_comment_line = -1;
%}


/* Define regular expression label */
letter [a-zA-Z_]
digit [0-9]
inum {digit}+
fnum {digit}+\.{digit}+
func fn\ {letter}
ident {letter}({letter}|{digit})*

%x STR
%x MLC

/* Rules section */
%%
"\""        { print_token("QUOTA"); BEGIN(STR); }
<STR>"\""   { print_token("QUOTA"); BEGIN(INITIAL); }
<STR>[^"]+  { print_token("STRING_LIT"); }
"/*"        { printf("%s", yytext); BEGIN(MLC); }
<MLC>"*/"   { print_token("MUTI_LINE_COMMENT"); BEGIN(INITIAL); last_comment_line = 1; }
<MLC>\n     { line_num++; comment_num++; printf("\n"); }
<MLC>.      { printf("%s", yytext); }
"+"         { print_token("ADD"); }
"-"         { print_token("SUB"); }
"*"         { print_token("MUL"); }
"/"         { print_token("QUO"); }
"%"         { print_token("REM"); }
">>"        { print_token("RSHIFT"); }
"<<"        { print_token("LSHIFT"); }
">"         { print_token("GTR"); }
"<"         { print_token("LSS"); }
">="        { print_token("GEQ"); }
"<="        { print_token("LEQ"); }
"=="        { print_token("EQL"); }
"&&"        { print_token("LAND"); }
"||"        { print_token("LOR"); }
"!"         { print_token("NOT"); }
"&"         { print_token("BAND"); }
"|"         { print_token("BOR"); }
"="         { print_token("ASSIGN"); }
"+="        { print_token("ADD_ASSIGN"); }
"-="        { print_token("SUB_ASSIGN"); }
"*="        { print_token("MUL_ASSIGN"); }
"/="        { print_token("QUO_ASSIGN"); }
"%="        { print_token("REM_ASSIGN"); }
"["         { print_token("LBRACK"); }
"]"         { print_token("RBRACK"); }
"("         { print_token("LPAREN"); }
")"         { print_token("RPAREN"); }
"{"         { print_token("LBRACE"); }
"}"         { print_token("RBRACE"); }
":"         { print_token("COLON"); }
";"         { print_token("SEMICOLON"); }
"if"        { print_token("IF"); }
"else"      { print_token("ELSE"); }
"for"       { print_token("FOR"); }
"in"        { print_token("IN"); }
"while"     { print_token("WHILE"); }
"loop"      { print_token("LOOP"); }
"break"     { print_token("BREAK"); }
"as"        { print_token("AS"); }
"let"       { print_token("LET"); }
"mut"       { print_token("MUT"); }
"i32"       { print_token("INT"); }
"f32"       { print_token("FLOAT"); }
{inum}      { print_token("INT_LIT"); }
{fnum}      { print_token("FLOAT_LIT"); }
{func}      { yyless(3); print_token("FUNC"); }
","         { print_token("COMMA"); }
"->"        { print_token("ARROW"); }
"print"     { print_token("PRINT"); }
"println"   { print_token("PRINTLN"); }
"return"    { print_token("RETURN"); }
".."        { print_token("DOTDOT"); }
"bool"      { print_token("BOOL"); }
"true"      { print_token("TRUE"); }
"false"     { print_token("FALSE"); }
{ident}     { print_token("IDENT"); }
\n          { 
            line_num++;
            print_token("NEWLINE");
            if (last_comment_line == 1)
                {
                comment_num++;
                last_comment_line = -1;
                }
            }
<<EOF>>     { line_num++; yyterminate(); }
"//".*      { comment_num++; print_token("COMMENT"); }
[ \t]+      {;}
.           {;}
%%

/*  C Code section */
int yywrap(void)
{
   return 1;
}

int main(int argc, char *argv[])
{
   if (argc == 2) {
       yyin = fopen(argv[1], "r");
   } else {
       yyin = stdin;
   }
   yylex();
   printf("\nFinish scanning,\n");
   printf("total line: %d\n", line_num);
   printf("comment line: %d\n", comment_num);
   fclose(yyin);
   return 0;
}
