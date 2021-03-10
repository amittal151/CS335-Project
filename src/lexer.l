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
int column = 0;
int line = 1;

extern int only_lexer;
extern FILE* lexer_file;

%}

%%

"/*"([^*]|(\*+[^*/]))*\*+\/		{ count(0); }

"//"[^\n]*      { /* consume //-comment */ }


"auto"			{ if( only_lexer ) fprintf(lexer_file,"AUTO\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(AUTO); }
"break"			{ if( only_lexer ) fprintf(lexer_file,"BREAK\t\t\t"); yylval.str = strdup(yytext); count(1); return(BREAK); }
"case"			{ if( only_lexer ) fprintf(lexer_file,"CASE\t\t\t"); yylval.str = strdup(yytext); count(1); return(CASE); }
"char"			{ if( only_lexer ) fprintf(lexer_file,"CHAR\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(CHAR); }
"const"			{ if( only_lexer ) fprintf(lexer_file,"CONST\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(CONST); }
"continue"		{ if( only_lexer ) fprintf(lexer_file,"CONTINUE\t\t\t"); yylval.str = strdup(yytext); count(1); return(CONTINUE); }
"default"		{ if( only_lexer ) fprintf(lexer_file,"DEFAULT\t\t\t"); yylval.str = strdup(yytext); count(1); return(DEFAULT); }
"do"			{ if( only_lexer ) fprintf(lexer_file,"DO\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(DO); }
"double"		{ if( only_lexer ) fprintf(lexer_file,"DOUBLE\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(DOUBLE); }
"else"			{ if( only_lexer ) fprintf(lexer_file,"ELSE\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(ELSE); }
"enum"			{ if( only_lexer ) fprintf(lexer_file,"ENUM\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(ENUM); }
"extern"		{ if( only_lexer ) fprintf(lexer_file,"EXTERN\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(EXTERN); }
"float"			{ if( only_lexer ) fprintf(lexer_file,"FLOAT\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(FLOAT); }
"for"			{ if( only_lexer ) fprintf(lexer_file,"FOR\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(FOR); }
"goto"			{ if( only_lexer ) fprintf(lexer_file,"GOTO\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(GOTO); }
"if"			{ if( only_lexer ) fprintf(lexer_file,"IF\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(IF); }
"int"			{ if( only_lexer ) fprintf(lexer_file,"INT\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(INT); }
"long"			{ if( only_lexer ) fprintf(lexer_file,"LONG\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(LONG); }
"register"		{ if( only_lexer ) fprintf(lexer_file,"REGISTER\t\t\t"); yylval.str = strdup(yytext); count(1); return(REGISTER); }
"return"		{ if( only_lexer ) fprintf(lexer_file,"RETURN\t\t\t"); yylval.str = strdup(yytext); count(1); return(RETURN); }
"short"			{ if( only_lexer ) fprintf(lexer_file,"SHORT\t\t\t"); yylval.str = strdup(yytext); count(1); return(SHORT); }
"signed"		{ if( only_lexer ) fprintf(lexer_file,"SIGNED\t\t\t"); yylval.str = strdup(yytext); count(1); return(SIGNED); }
"sizeof"		{ if( only_lexer ) fprintf(lexer_file,"SIZEOF\t\t\t"); yylval.str = strdup(yytext); count(1); return(SIZEOF); }
"static"		{ if( only_lexer ) fprintf(lexer_file,"STATIC\t\t\t"); yylval.str = strdup(yytext); count(1); return(STATIC); }
"struct"		{ if( only_lexer ) fprintf(lexer_file,"STRUCT\t\t\t"); yylval.str = strdup(yytext); count(1); return(STRUCT); }
"switch"		{ if( only_lexer ) fprintf(lexer_file,"SWITCH\t\t\t");  yylval.str = strdup(yytext); count(1); return(SWITCH); }
"typedef"		{ if( only_lexer ) fprintf(lexer_file,"TYPEDEF\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(TYPEDEF); }
"union"			{ if( only_lexer ) fprintf(lexer_file,"UNION\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(UNION); }
"unsigned"		{ if( only_lexer ) fprintf(lexer_file,"UNSIGNED\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(UNSIGNED); }
"void"			{ if( only_lexer ) fprintf(lexer_file,"VOID\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(VOID); }
"volatile"		{ if( only_lexer ) fprintf(lexer_file,"VOLATILE\t"); yylval.str = strdup(yytext); count(1); return(VOLATILE); }
"while"			{ if( only_lexer ) fprintf(lexer_file,"WHILE\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(WHILE); }

{L}({L}|{D})*		{ if( only_lexer ) fprintf(lexer_file,"IDENTIFIER\t\t"); yylval.str = strdup(yytext); count(1); return(check_type()); }

0[xX]{H}+{IS}?		{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }
0{D}+{IS}?		{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }
{D}+{IS}?		{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }
L?'(\\.|[^\\'])+'	{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }

{D}+{E}{FS}?		{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ if( only_lexer ) fprintf(lexer_file,"CONSTANT\t\t"); yylval.str = strdup(yytext); count(1); return(CONSTANT); }

L?\"(\\.|[^\\"])*\"	{ if( only_lexer ) fprintf(lexer_file,"STRING_LITERAL\t"); yylval.str = strdup(yytext); count(1); return(STRING_LITERAL); }

"..."			{ if( only_lexer ) fprintf(lexer_file,"ELLIPSIS\t\t"); yylval.str = strdup(yytext); count(1); return(ELLIPSIS); }
">>="			{ if( only_lexer ) fprintf(lexer_file,"RIGHT_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(RIGHT_ASSIGN); }
"<<="			{ if( only_lexer ) fprintf(lexer_file,"LEFT_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(LEFT_ASSIGN); }
"+="			{ if( only_lexer ) fprintf(lexer_file,"ADD_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(ADD_ASSIGN); }
"-="			{ if( only_lexer ) fprintf(lexer_file,"SUB_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(SUB_ASSIGN); }
"*="			{ if( only_lexer ) fprintf(lexer_file,"MUL_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(MUL_ASSIGN); }
"/="			{ if( only_lexer ) fprintf(lexer_file,"DIV_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(DIV_ASSIGN); }
"%="			{ if( only_lexer ) fprintf(lexer_file,"MOD_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(MOD_ASSIGN); }
"&="			{ if( only_lexer ) fprintf(lexer_file,"AND_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(AND_ASSIGN); }
"^="			{ if( only_lexer ) fprintf(lexer_file,"XOR_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(XOR_ASSIGN); }
"|="			{ if( only_lexer ) fprintf(lexer_file,"OR_ASSIGN\t\t"); yylval.str = strdup(yytext); count(1); return(OR_ASSIGN); }
">>"			{ if( only_lexer ) fprintf(lexer_file,"RIGHT_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(RIGHT_OP); }
"<<"			{ if( only_lexer ) fprintf(lexer_file,"LEFT_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(LEFT_OP); }
"++"			{ if( only_lexer ) fprintf(lexer_file,"INC_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(INC_OP); }
"--"			{ if( only_lexer ) fprintf(lexer_file,"DEC_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(DEC_OP); }
"->"			{ if( only_lexer ) fprintf(lexer_file,"PTR_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(PTR_OP); }
"&&"			{ if( only_lexer ) fprintf(lexer_file,"AND_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(AND_OP); }
"||"			{ if( only_lexer ) fprintf(lexer_file,"OR_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(OR_OP); }
"<="			{ if( only_lexer ) fprintf(lexer_file,"LE_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(LE_OP); }
">="			{ if( only_lexer ) fprintf(lexer_file,"GE_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(GE_OP); }
"=="			{ if( only_lexer ) fprintf(lexer_file,"EQ_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(EQ_OP); }
"!="			{ if( only_lexer ) fprintf(lexer_file,"NE_OP\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(NE_OP); }
";"			{ if( only_lexer ) fprintf(lexer_file,";\t\t\t\t");  yylval.str = strdup(yytext); count(1); return(';'); }
("{"|"<%")		{ if( only_lexer ) fprintf(lexer_file,"{\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('{'); }
("}"|"%>")		{ if( only_lexer ) fprintf(lexer_file,"}\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('}'); }
","			{ if( only_lexer ) fprintf(lexer_file,",\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(','); }
":"			{ if( only_lexer ) fprintf(lexer_file,":\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(':'); }
"="			{ if( only_lexer ) fprintf(lexer_file,"=\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('='); }
"("			{ if( only_lexer ) fprintf(lexer_file,"(\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('('); }
")"			{ if( only_lexer ) fprintf(lexer_file,")\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(')'); }
("["|"<:")		{ if( only_lexer ) fprintf(lexer_file,"[\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('['); }
("]"|":>")		{ if( only_lexer ) fprintf(lexer_file,"]\t\t\t\t"); yylval.str = strdup(yytext); count(1); return(']'); }
"."			{ if( only_lexer ) fprintf(lexer_file,".\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('.'); }
"&"			{ if( only_lexer ) fprintf(lexer_file,"&\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('&'); }
"!"			{ if( only_lexer ) fprintf(lexer_file,"!\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('!'); }
"~"			{ if( only_lexer ) fprintf(lexer_file,"~\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('~'); }
"-"			{ if( only_lexer ) fprintf(lexer_file,"-\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('-'); }
"+"			{ if( only_lexer ) fprintf(lexer_file,"+\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('+'); }
"*"			{ if( only_lexer ) fprintf(lexer_file,"*\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('*'); }
"/"			{ if( only_lexer ) fprintf(lexer_file,"/\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('/'); }
"%"			{ if( only_lexer ) fprintf(lexer_file,"%%\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('%'); }
"<"			{ if( only_lexer ) fprintf(lexer_file,"<\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('<'); }
">"			{ if( only_lexer ) fprintf(lexer_file,">\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('>'); }
"^"			{ if( only_lexer ) fprintf(lexer_file,"^\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('^'); }
"|"			{ if( only_lexer ) fprintf(lexer_file,"|\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('|'); }
"?"			{ if( only_lexer ) fprintf(lexer_file,"?\t\t\t\t"); yylval.str = strdup(yytext); count(1); return('?'); }

[ \t\v\n\f]		{ count(0); }
.			{ if( only_lexer ) fprintf(lexer_file, "Unknown character\(s\): %s\n", yytext); return -1;}

%%

int yywrap()
{
	return(1);
}

void count(int flag)
{
	int i;
    if(flag){
        if( only_lexer ) fprintf(lexer_file,"%s\t\t\t\t", yytext);
        if( only_lexer ) fprintf(lexer_file,"%d\t\t%d\n",line, column);
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


// void print_options(){
// 	// To be constructed later
// 	cout<<"\t--help\t\t\tDisplay available options\n";

// 	cout<<"\n\n";
// }

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
