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
#include "AST.h"
#include "parser.hpp"

void count(int);
int check_type();
void comment();
int error_handler();
void print_options();

%}

%%

"/*"([^*]|(\*+[^*/]))*\*+\/		{ count(0); }

"//"[^\n]*      { /* consume //-comment */ }


"auto"			{ cout<<"AUTO\t\t"; yylval.str = strdup(yytext); count(1); return(AUTO); }
"break"			{ cout<<"BREAK\t\t"; yylval.str = strdup(yytext); count(1); return(BREAK); }
"case"			{ cout<<"CASE\t\t"; yylval.str = strdup(yytext); count(1); return(CASE); }
"char"			{ cout<<"CHAR\t\t"; yylval.str = strdup(yytext); count(1); return(CHAR); }
"const"			{ cout<<"CONST\t\t"; yylval.str = strdup(yytext); count(1); return(CONST); }
"continue"		{ cout<<"CONTINUE\t\t"; yylval.str = strdup(yytext); count(1); return(CONTINUE); }
"default"		{ cout<<"DEFAULT\t\t"; yylval.str = strdup(yytext); count(1); return(DEFAULT); }
"do"			{ cout<<"DO\t\t"; yylval.str = strdup(yytext); count(1); return(DO); }
"double"		{ cout<<"DOUBLE\t\t"; yylval.str = strdup(yytext); count(1); return(DOUBLE); }
"else"			{ cout<<"ELSE\t\t"; yylval.str = strdup(yytext); count(1); return(ELSE); }
"enum"			{ cout<<"ENUM\t\t"; yylval.str = strdup(yytext); count(1); return(ENUM); }
"extern"		{ cout<<"EXTERN\t\t"; yylval.str = strdup(yytext); count(1); return(EXTERN); }
"float"			{ cout<<"FLOAT\t\t"; yylval.str = strdup(yytext); count(1); return(FLOAT); }
"for"			{ cout<<"FOR\t\t"; yylval.str = strdup(yytext); count(1); return(FOR); }
"goto"			{ cout<<"GOTO\t\t"; yylval.str = strdup(yytext); count(1); return(GOTO); }
"if"			{ cout<<"IF\t\t"; yylval.str = strdup(yytext); count(1); return(IF); }
"int"			{ cout<<"INT\t\t"; yylval.str = strdup(yytext); count(1); return(INT); }
"long"			{ cout<<"LONG\t\t"; yylval.str = strdup(yytext); count(1); return(LONG); }
"register"		{ cout<<"REGISTER\t\t"; yylval.str = strdup(yytext); count(1); return(REGISTER); }
"return"		{ cout<<"RETURN\t\t"; yylval.str = strdup(yytext); count(1); return(RETURN); }
"short"			{ cout<<"SHORT\t\t"; yylval.str = strdup(yytext); count(1); return(SHORT); }
"signed"		{ cout<<"SIGNED\t\t"; yylval.str = strdup(yytext); count(1); return(SIGNED); }
"sizeof"		{ cout<<"SIZEOF\t\t"; yylval.str = strdup(yytext); count(1); return(SIZEOF); }
"static"		{ cout<<"STATIC\t\t"; yylval.str = strdup(yytext); count(1); return(STATIC); }
"struct"		{ cout<<"STRUCT\t\t"; yylval.str = strdup(yytext); count(1); return(STRUCT); }
"switch"		{ cout<<"SWITCH\t\t";  yylval.str = strdup(yytext); count(1); return(SWITCH); }
"typedef"		{ cout<<"TYPEDEF\t\t"; yylval.str = strdup(yytext); count(1); return(TYPEDEF); }
"union"			{ cout<<"UNION\t\t"; yylval.str = strdup(yytext); count(1); return(UNION); }
"unsigned"		{ cout<<"UNSIGNED\t"; yylval.str = strdup(yytext); count(1); return(UNSIGNED); }
"void"			{ cout<<"VOID\t\t"; yylval.str = strdup(yytext); count(1); return(VOID); }
"volatile"		{ cout<<"VOLATILE\t"; yylval.str = strdup(yytext); count(1); return(VOLATILE); }
"while"			{ cout<<"WHILE\t\t"; yylval.str = strdup(yytext); count(1); return(WHILE); }

{L}({L}|{D})*		{ cout<<"IDENTIFIER\t"; yylval.str = strdup(yytext); count(1); return(check_type()); }

0[xX]{H}+{IS}?		{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }
0{D}+{IS}?		{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }
{D}+{IS}?		{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }
L?'(\\.|[^\\'])+'	{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }

{D}+{E}{FS}?		{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ cout<<"CONSTANT\t"; yylval.str = strdup(yytext); count(1); return(CONSTANT); }

L?\"(\\.|[^\\"])*\"	{ cout<<"STRING_LITERAL\t"; yylval.str = strdup(yytext); count(1); return(STRING_LITERAL); }

"..."			{ cout<<"ELLIPSIS\t"; yylval.str = strdup(yytext); count(1); return(ELLIPSIS); }
">>="			{ cout<<"RIGHT_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(RIGHT_ASSIGN); }
"<<="			{ cout<<"LEFT_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(LEFT_ASSIGN); }
"+="			{ cout<<"ADD_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(ADD_ASSIGN); }
"-="			{ cout<<"SUB_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(SUB_ASSIGN); }
"*="			{ cout<<"MUL_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(MUL_ASSIGN); }
"/="			{ cout<<"DIV_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(DIV_ASSIGN); }
"%="			{ cout<<"MOD_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(MOD_ASSIGN); }
"&="			{ cout<<"AND_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(AND_ASSIGN); }
"^="			{ cout<<"XOR_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(XOR_ASSIGN); }
"|="			{ cout<<"OR_ASSIGN\t"; yylval.str = strdup(yytext); count(1); return(OR_ASSIGN); }
">>"			{ cout<<"RIGHT_OP\t"; yylval.str = strdup(yytext); count(1); return(RIGHT_OP); }
"<<"			{ cout<<"LEFT_OP\t\t"; yylval.str = strdup(yytext); count(1); return(LEFT_OP); }
"++"			{ cout<<"INC_OP\t\t"; yylval.str = strdup(yytext); count(1); return(INC_OP); }
"--"			{ cout<<"DEC_OP\t\t"; yylval.str = strdup(yytext); count(1); return(DEC_OP); }
"->"			{ cout<<"PTR_OP\t\t"; yylval.str = strdup(yytext); count(1); return(PTR_OP); }
"&&"			{ cout<<"AND_OP\t\t"; yylval.str = strdup(yytext); count(1); return(AND_OP); }
"||"			{ cout<<"OR_OP\t\t"; yylval.str = strdup(yytext); count(1); return(OR_OP); }
"<="			{ cout<<"LE_OP\t\t"; yylval.str = strdup(yytext); count(1); return(LE_OP); }
">="			{ cout<<"GE_OP\t\t"; yylval.str = strdup(yytext); count(1); return(GE_OP); }
"=="			{ cout<<"EQ_OP\t\t"; yylval.str = strdup(yytext); count(1); return(EQ_OP); }
"!="			{ cout<<"NE_OP\t\t"; yylval.str = strdup(yytext); count(1); return(NE_OP); }
";"			{ cout<<";\t\t";  yylval.str = strdup(yytext); count(1); return(';'); }
("{"|"<%")		{ cout<<"{\t\t"; yylval.str = strdup(yytext); count(1); return('{'); }
("}"|"%>")		{ cout<<"}\t\t"; yylval.str = strdup(yytext); count(1); return('}'); }
","			{ cout<<",\t\t"; yylval.str = strdup(yytext); count(1); return(','); }
":"			{ cout<<":\t\t"; yylval.str = strdup(yytext); count(1); return(':'); }
"="			{ cout<<"=\t\t"; yylval.str = strdup(yytext); count(1); return('='); }
"("			{ cout<<"(\t\t"; yylval.str = strdup(yytext); count(1); return('('); }
")"			{ cout<<")\t\t"; yylval.str = strdup(yytext); count(1); return(')'); }
("["|"<:")		{ cout<<"[\t\t"; yylval.str = strdup(yytext); count(1); return('['); }
("]"|":>")		{ cout<<"]\t\t"; yylval.str = strdup(yytext); count(1); return(']'); }
"."			{ cout<<".\t\t"; yylval.str = strdup(yytext); count(1); return('.'); }
"&"			{ cout<<"&\t\t"; yylval.str = strdup(yytext); count(1); return('&'); }
"!"			{ cout<<"!\t\t"; yylval.str = strdup(yytext); count(1); return('!'); }
"~"			{ cout<<"~\t\t"; yylval.str = strdup(yytext); count(1); return('~'); }
"-"			{ cout<<"-\t\t"; yylval.str = strdup(yytext); count(1); return('-'); }
"+"			{ cout<<"+\t\t"; yylval.str = strdup(yytext); count(1); return('+'); }
"*"			{ cout<<"*\t\t"; yylval.str = strdup(yytext); count(1); return('*'); }
"/"			{ cout<<"/\t\t"; yylval.str = strdup(yytext); count(1); return('/'); }
"%"			{ cout<<"%%\t\t"; yylval.str = strdup(yytext); count(1); return('%'); }
"<"			{ cout<<"<\t\t"; yylval.str = strdup(yytext); count(1); return('<'); }
">"			{ cout<<">\t\t"; yylval.str = strdup(yytext); count(1); return('>'); }
"^"			{ cout<<"^\t\t"; yylval.str = strdup(yytext); count(1); return('^'); }
"|"			{ cout<<"|\t\t"; yylval.str = strdup(yytext); count(1); return('|'); }
"?"			{ cout<<"?\t\t"; yylval.str = strdup(yytext); count(1); return('?'); }

[ \t\v\n\f]		{ count(0); }
.			{ return error_handler(); /* Return error on bad characters */ }

%%

int yywrap()
{
	return(1);
}

int column = 0;
int line = 1;

int error_handler(){
	cerr<<"Error : Bad character "<<yytext<<" in line# "<<line<<", and column# "<<column + 1<<"\n"; 
	return(0);
}

void count(int flag)
{
	int i;
    if(flag){
        cout<<yytext<<"\t\t";
        cout<<line<<"\t\t"<<column+1<<"\n";
    }

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n'){
			column = 0;
            line ++;
        }
		else if (yytext[i] == '\t')
			column += 4 - (column% 4);
		else
			column++;
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


void print_options(){
	// To be constructed later
	cout<<"\t--help\t\t\tDisplay available options\n";

	cout<<"\n\n";
}

// int main(int argc, char* argv[]){
	
// 	if(argc <= 1){
//     	cout<<"Error: no input files\n";
//   		return -1;
//   	}
  	
//   	for(int i = 1; i<argc; i++){
//   		if(!strcmp(argv[i], "--help")){
// 			goto help;
// 		}
//   	}
  	
// 	for(int i = 1; i<argc; i++){
// 		yyin = fopen(argv[i], "r");
		
// 		// File open failed, proceeding to next file(s), if exist
// 		if(yyin == NULL){
// 			cout<<"Error: cannot open file "<<argv[i]<<"\n\n";
// 			continue;
// 		}
		
// 		yyrestart(yyin);

// 		line = 1, column = 0;
// 		cout<<"---------Output for file "<<argv[i]<<"----------\n";
// 		cout<<"Token\t\tLexeme\t\tLine#\t\tColumn#\t\t\n";
	
// 		while( yylex() > 0 ){
		
// 		}
// 		cout<<"---------------------------------------------------\n";
// 	}
	
// 	return 0;
	
// 	help:
// 	cout<<"OVERVIEW: C Compiler Lexer\n\n";
// 	cout<<"USAGE: lexer [options] file1 file2 ...\n\n";
// 	cout<<"OPTIONS:\n";
// 	print_options();
// 	return 0;
	
// }
