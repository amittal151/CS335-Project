D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{
#include <stdio.h>
#include "y.tab.h"

void count(int);
int check_type();
void comment();
%}

%%
"/*"			{ comment(); }
"//"[^\n]*      { /* consume //-comment */ }


"auto"			{ printf("AUTO\t\t"); count(1); return(AUTO); }
"break"			{ printf("BREAK\t\t"); count(1); return(BREAK); }
"case"			{ printf("CASE\t\t"); count(1); return(CASE); }
"char"			{ printf("CHAR\t\t"); count(1); return(CHAR); }
"const"			{ printf("CONST\t\t"); count(1); return(CONST); }
"continue"		{ printf("CONTINUE\t\t"); count(1); return(CONTINUE); }
"default"		{ printf("DEFAULT\t\t"); count(1); return(DEFAULT); }
"do"			{ printf("DO\t\t"); count(1); return(DO); }
"double"		{ printf("DOUBLE\t\t"); count(1); return(DOUBLE); }
"else"			{ printf("ELSE\t\t"); count(1); return(ELSE); }
"enum"			{ printf("ENUM\t\t"); count(1); return(ENUM); }
"extern"		{ printf("EXTERN\t\t"); count(1); return(EXTERN); }
"float"			{ printf("FLOAT\t\t"); count(1); return(FLOAT); }
"for"			{ printf("FOR\t\t"); count(1); return(FOR); }
"goto"			{ printf("GOTO\t\t"); count(1); return(GOTO); }
"if"			{ printf("IF\t\t"); count(1); return(IF); }
"int"			{ printf("INT\t\t"); count(1); return(INT); }
"long"			{ printf("LONG\t\t"); count(1); return(LONG); }
"register"		{ printf("REGISTER\t\t"); count(1); return(REGISTER); }
"return"		{ printf("RETURN\t\t"); count(1); return(RETURN); }
"short"			{ printf("SHORT\t\t"); count(1); return(SHORT); }
"signed"		{ printf("SIGNED\t\t"); count(1); return(SIGNED); }
"sizeof"		{ printf("SIZEOF\t\t"); count(1); return(SIZEOF); }
"static"		{ printf("STATIC\t\t"); count(1); return(STATIC); }
"struct"		{ printf("STRUCT\t\t"); count(1); return(STRUCT); }
"switch"		{ printf("SWITCH\t\t"); count(1); return(SWITCH); }
"typedef"		{ printf("TYPEDEF\t\t"); count(1); return(TYPEDEF); }
"union"			{ printf("UNION\t\t"); count(1); return(UNION); }
"unsigned"		{ printf("UNSIGNED\t"); count(1); return(UNSIGNED); }
"void"			{ printf("VOID\t\t"); count(1); return(VOID); }
"volatile"		{ printf("VOLATILE\t"); count(1); return(VOLATILE); }
"while"			{ printf("WHILE\t\t"); count(1); return(WHILE); }

{L}({L}|{D})*		{ printf("IDENTIFIER\t"); count(1); return(check_type()); }

0[xX]{H}+{IS}?		{ printf("CONSTANT\t"); count(1); return(CONSTANT); }
0{D}+{IS}?		{ printf("CONSTANT\t"); count(1); return(CONSTANT); }
{D}+{IS}?		{ printf("CONSTANT\t"); count(1); return(CONSTANT); }
L?'(\\.|[^\\'])+'	{ printf("CONSTANT\t"); count(1); return(CONSTANT); }

{D}+{E}{FS}?		{ printf("CONSTANT\t"); count(1); return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ printf("CONSTANT\t"); count(1); return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ printf("CONSTANT\t"); count(1); return(CONSTANT); }

L?\"(\\.|[^\\"])*\"	{ printf("STRING_LITERAL\t"); count(1); return(STRING_LITERAL); }

"..."			{ printf("ELLIPSIS\t"); count(1); return(ELLIPSIS); }
">>="			{ printf("RIGHT_ASSIGN\t"); count(1); return(RIGHT_ASSIGN); }
"<<="			{ printf("LEFT_ASSIGN\t"); count(1); return(LEFT_ASSIGN); }
"+="			{ printf("ADD_ASSIGN\t"); count(1); return(ADD_ASSIGN); }
"-="			{ printf("SUB_ASSIGN\t"); count(1); return(SUB_ASSIGN); }
"*="			{ printf("MUL_ASSIGN\t"); count(1); return(MUL_ASSIGN); }
"/="			{ printf("DIV_ASSIGN\t"); count(1); return(DIV_ASSIGN); }
"%="			{ printf("MOD_ASSIGN\t"); count(1); return(MOD_ASSIGN); }
"&="			{ printf("AND_ASSIGN\t"); count(1); return(AND_ASSIGN); }
"^="			{ printf("XOR_ASSIGN\t"); count(1); return(XOR_ASSIGN); }
"|="			{ printf("OR_ASSIGN\t"); count(1); return(OR_ASSIGN); }
">>"			{ printf("RIGHT_OP\t"); count(1); return(RIGHT_OP); }
"<<"			{ printf("LEFT_OP\t\t"); count(1); return(LEFT_OP); }
"++"			{ printf("INC_OP\t\t"); count(1); return(INC_OP); }
"--"			{ printf("DEC_OP\t\t"); count(1); return(DEC_OP); }
"->"			{ printf("PTR_OP\t\t"); count(1); return(PTR_OP); }
"&&"			{ printf("AND_OP\t\t"); count(1); return(AND_OP); }
"||"			{ printf("OR_OP\t\t"); count(1); return(OR_OP); }
"<="			{ printf("LE_OP\t\t"); count(1); return(LE_OP); }
">="			{ printf("GE_OP\t\t"); count(1); return(GE_OP); }
"=="			{ printf("EQ_OP\t\t"); count(1); return(EQ_OP); }
"!="			{ printf("NE_OP\t\t"); count(1); return(NE_OP); }
";"			{ printf(";\t\t"); count(1); return(';'); }
("{"|"<%")		{ printf("{\t\t"); count(1); return('{'); }
("}"|"%>")		{ printf("}\t\t"); count(1); return('}'); }
","			{ printf(",\t\t"); count(1); return(','); }
":"			{ printf(":\t\t"); count(1); return(':'); }
"="			{ printf("=\t\t"); count(1); return('='); }
"("			{ printf("(\t\t"); count(1); return('('); }
")"			{ printf(")\t\t"); count(1); return(')'); }
("["|"<:")		{ printf("[\t\t"); count(1); return('['); }
("]"|":>")		{ printf("]\t\t"); count(1); return(']'); }
"."			{ printf(".\t\t"); count(1); return('.'); }
"&"			{ printf("&\t\t"); count(1); return('&'); }
"!"			{ printf("!\t\t"); count(1); return('!'); }
"~"			{ printf("~\t\t"); count(1); return('~'); }
"-"			{ printf("-\t\t"); count(1); return('-'); }
"+"			{ printf("+\t\t"); count(1); return('+'); }
"*"			{ printf("*\t\t"); count(1); return('*'); }
"/"			{ printf("/\t\t"); count(1); return('/'); }
"%"			{ printf("%%\t\t"); count(1); return('%'); }
"<"			{ printf("<\t\t"); count(1); return('<'); }
">"			{ printf(">\t\t"); count(1); return('>'); }
"^"			{ printf("^\t\t"); count(1); return('^'); }
"|"			{ printf("|\t\t"); count(1); return('|'); }
"?"			{ printf("?\t\t"); count(1); return('?'); }

[ \t\v\n\f]		{ count(0); }
.			{ /* ignore bad characters */ }

%%

int yywrap()
{
	return(1);
}


void comment()
{
	char c, c1;

loop:
	while ((c = input()) != '*' && c != 0)
		putchar(c);

	if ((c1 = input()) != '/' && c != 0)
	{
		unput(c1);
		goto loop;
	}

	if (c != 0)
		putchar(c1);
}


int column = 1;
int line = 1;

void count(int flag)
{
	int i;
    if(flag){
        printf("%s\t\t", yytext);
        printf("%d\t%d\n", line, column);
    }

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n'){
			column = 1;
            line ++;
        }
		else if (yytext[i] == '\t')
			column += 7 - ((column -1)% 8);
		else
			column++;
	// ECHO;
}


int check_type()
{
/*
* pseudo code --- this is what it should check
*
*	if (yytext == type_name)
*		return(TYPE_NAME);
*
*	return(IDENTIFIER);
*/

/*
*	it actually will only return IDENTIFIER
*/

	return(IDENTIFIER);
}