D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{
#include <stdio.h>
#include <iostream>
using namespace std;
#include "parser.hpp"

void count(int);
int check_type();
void comment();
%}

%%
"/*"			{ comment(); }
"//"[^\n]*      { /* consume //-comment */ }


"auto"			{ cout<<"AUTO\t\t"; count(1); return(AUTO); }
"break"			{ cout<<"BREAK\t\t"; count(1); return(BREAK); }
"case"			{ cout<<"CASE\t\t"; count(1); return(CASE); }
"char"			{ cout<<"CHAR\t\t"; count(1); return(CHAR); }
"const"			{ cout<<"CONST\t\t"; count(1); return(CONST); }
"continue"		{ cout<<"CONTINUE\t\t"; count(1); return(CONTINUE); }
"default"		{ cout<<"DEFAULT\t\t"; count(1); return(DEFAULT); }
"do"			{ cout<<"DO\t\t"; count(1); return(DO); }
"double"		{ cout<<"DOUBLE\t\t"; count(1); return(DOUBLE); }
"else"			{ cout<<"ELSE\t\t"; count(1); return(ELSE); }
"enum"			{ cout<<"ENUM\t\t"; count(1); return(ENUM); }
"extern"		{ cout<<"EXTERN\t\t"; count(1); return(EXTERN); }
"float"			{ cout<<"FLOAT\t\t"; count(1); return(FLOAT); }
"for"			{ cout<<"FOR\t\t"; count(1); return(FOR); }
"goto"			{ cout<<"GOTO\t\t"; count(1); return(GOTO); }
"if"			{ cout<<"IF\t\t"; count(1); return(IF); }
"int"			{ cout<<"INT\t\t"; count(1); return(INT); }
"long"			{ cout<<"LONG\t\t"; count(1); return(LONG); }
"register"		{ cout<<"REGISTER\t\t"; count(1); return(REGISTER); }
"return"		{ cout<<"RETURN\t\t"; count(1); return(RETURN); }
"short"			{ cout<<"SHORT\t\t"; count(1); return(SHORT); }
"signed"		{ cout<<"SIGNED\t\t"; count(1); return(SIGNED); }
"sizeof"		{ cout<<"SIZEOF\t\t"; count(1); return(SIZEOF); }
"static"		{ cout<<"STATIC\t\t"; count(1); return(STATIC); }
"struct"		{ cout<<"STRUCT\t\t"; count(1); return(STRUCT); }
"switch"		{ cout<<"SWITCH\t\t"; count(1); return(SWITCH); }
"typedef"		{ cout<<"TYPEDEF\t\t"; count(1); return(TYPEDEF); }
"union"			{ cout<<"UNION\t\t"; count(1); return(UNION); }
"unsigned"		{ cout<<"UNSIGNED\t"; count(1); return(UNSIGNED); }
"void"			{ cout<<"VOID\t\t"; count(1); return(VOID); }
"volatile"		{ cout<<"VOLATILE\t"; count(1); return(VOLATILE); }
"while"			{ cout<<"WHILE\t\t"; count(1); return(WHILE); }

{L}({L}|{D})*		{ cout<<"IDENTIFIER\t"; count(1); return(check_type()); }

0[xX]{H}+{IS}?		{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }
0{D}+{IS}?		{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }
{D}+{IS}?		{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }
L?'(\\.|[^\\'])+'	{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }

{D}+{E}{FS}?		{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ cout<<"CONSTANT\t"; count(1); return(CONSTANT); }

L?\"(\\.|[^\\"])*\"	{ cout<<"STRING_LITERAL\t)"; count(1); return(STRING_LITERAL); }

"..."			{ cout<<"ELLIPSIS\t"; count(1); return(ELLIPSIS); }
">>="			{ cout<<"RIGHT_ASSIGN\t"; count(1); return(RIGHT_ASSIGN); }
"<<="			{ cout<<"LEFT_ASSIGN\t"; count(1); return(LEFT_ASSIGN); }
"+="			{ cout<<"ADD_ASSIGN\t"; count(1); return(ADD_ASSIGN); }
"-="			{ cout<<"SUB_ASSIGN\t"; count(1); return(SUB_ASSIGN); }
"*="			{ cout<<"MUL_ASSIGN\t"; count(1); return(MUL_ASSIGN); }
"/="			{ cout<<"DIV_ASSIGN\t"; count(1); return(DIV_ASSIGN); }
"%="			{ cout<<"MOD_ASSIGN\t"; count(1); return(MOD_ASSIGN); }
"&="			{ cout<<"AND_ASSIGN\t"; count(1); return(AND_ASSIGN); }
"^="			{ cout<<"XOR_ASSIGN\t"; count(1); return(XOR_ASSIGN); }
"|="			{ cout<<"OR_ASSIGN\t"; count(1); return(OR_ASSIGN); }
">>"			{ cout<<"RIGHT_OP\t"; count(1); return(RIGHT_OP); }
"<<"			{ cout<<"LEFT_OP\t\t"; count(1); return(LEFT_OP); }
"++"			{ cout<<"INC_OP\t\t"; count(1); return(INC_OP); }
"--"			{ cout<<"DEC_OP\t\t"; count(1); return(DEC_OP); }
"->"			{ cout<<"PTR_OP\t\t"; count(1); return(PTR_OP); }
"&&"			{ cout<<"AND_OP\t\t"; count(1); return(AND_OP); }
"||"			{ cout<<"OR_OP\t\t"; count(1); return(OR_OP); }
"<="			{ cout<<"LE_OP\t\t"; count(1); return(LE_OP); }
">="			{ cout<<"GE_OP\t\t"; count(1); return(GE_OP); }
"=="			{ cout<<"EQ_OP\t\t"; count(1); return(EQ_OP); }
"!="			{ cout<<"NE_OP\t\t"; count(1); return(NE_OP); }
";"			{ cout<<";\t\t"; count(1); return(';'); }
("{"|"<%")		{ cout<<"{\t\t"; count(1); return('{'); }
("}"|"%>")		{ cout<<"}\t\t"; count(1); return('}'); }
","			{ cout<<",\t\t"; count(1); return(','); }
":"			{ cout<<":\t\t"; count(1); return(':'); }
"="			{ cout<<"=\t\t"; count(1); return('='); }
"("			{ cout<<"(\t\t"; count(1); return('('); }
")"			{ cout<<")\t\t"; count(1); return(')'); }
("["|"<:")		{ cout<<"[\t\t"; count(1); return('['); }
("]"|":>")		{ cout<<"]\t\t"; count(1); return(']'); }
"."			{ cout<<".\t\t"; count(1); return('.'); }
"&"			{ cout<<"&\t\t"; count(1); return('&'); }
"!"			{ cout<<"!\t\t"; count(1); return('!'); }
"~"			{ cout<<"~\t\t"; count(1); return('~'); }
"-"			{ cout<<"-\t\t"; count(1); return('-'); }
"+"			{ cout<<"+\t\t"; count(1); return('+'); }
"*"			{ cout<<"*\t\t"; count(1); return('*'); }
"/"			{ cout<<"/\t\t"; count(1); return('/'); }
"%"			{ cout<<"%%\t\t"; count(1); return('%'); }
"<"			{ cout<<"<\t\t"; count(1); return('<'); }
">"			{ cout<<">\t\t"; count(1); return('>'); }
"^"			{ cout<<"^\t\t"; count(1); return('^'); }
"|"			{ cout<<"|\t\t"; count(1); return('|'); }
"?"			{ cout<<"?\t\t"; count(1); return('?'); }

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
	while ((c = yyinput()) != '*' && c != 0)
		putchar(c);

	if ((c1 = yyinput()) != '/' && c != 0)
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
        cout<<yytext<<"\t\t";
        cout<<line<<"\t\t"<<column<<"\n";
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

int main(int argc, char* argv[]){
	if(argc <= 1){
    	cout<<"Inadequate number of parameters.\n";
  		return -1;
  	}
  	
	for(int i = 1; i<argc; i++){
		yyin = fopen(argv[1], "r");
		line = 1, column = 1;
		cout<<"---------Output for file "<<argv[i]<<"----------\n";
		cout<<"Token\t\tLexeme\t\tLine#\t\tColumn\t\t\n";
		
		while( yylex() > 0 ){
		
		}
		cout<<"------------------------------------------------\n";
	}

}
