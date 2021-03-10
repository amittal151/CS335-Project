%{
#include <stdio.h>
#include <iostream>
#include "AST.h"
extern char* yytext;
extern int column;
extern int line;
int yyerror(char*);
int yylex();
FILE* dotfile;

extern int yylex();
extern int yyrestart(FILE*);
extern FILE* yyin;
%}

%union{
	char* str;
	int number;
	treeNode* ptr;
}

%token<str> IDENTIFIER CONSTANT STRING_LITERAL SIZEOF
%token<str> PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token<str> AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token<str> SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token<str> XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token<str> TYPEDEF EXTERN STATIC AUTO REGISTER
%token<str> CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token<str> STRUCT UNION ENUM ELLIPSIS
%token<str> CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%start translation_unit


%type<ptr> primary_expression postfix_expression argument_expression_list unary_expression unary_operator cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression
%type<str> assignment_operator 
%type<ptr> and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression 
%type<ptr> assignment_expression expression constant_expression declaration declaration_specifiers init_declarator_list
%type<ptr> declarator direct_declarator pointer type_qualifier_list parameter_type_list parameter_list parameter_declaration identifier_list type_name abstract_declarator direct_abstract_declarator initializer
%type<ptr> init_declarator type_specifier struct_or_union_specifier	struct_declaration_list struct_declaration specifier_qualifier_list struct_declarator_list struct_declarator enum_specifier enumerator_list enumerator type_qualifier
%type<ptr> statement labeled_statement compound_statement declaration_list statement_list expression_statement selection_statement iteration_statement jump_statement translation_unit external_declaration function_definition initializer_list
%type<ptr> storage_class_specifier
%type<str> struct_or_union

%left ';'

%%


primary_expression
    : IDENTIFIER {
    	$$ = makeleaf($1);
    }
	| CONSTANT 	{
		$$ = makeleaf($1);
	}
	| STRING_LITERAL {
		$$ = makeleaf($1);
	}
	| '(' expression ')' {
		$$ = $2;
	}
	;

postfix_expression
	: primary_expression {
		$$ = $1;
	}
	| postfix_expression '[' expression ']' {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("postfix_expression", attr);
	}
	| postfix_expression '(' ')' {
		$$ = $1;
	}
	| postfix_expression '(' argument_expression_list ')' {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("postfix_expression", attr);
	}
	| postfix_expression '.' IDENTIFIER {
		// TODO
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, makeleaf($3), "", 1);
		$$ = makenode("expression.id", attr);
	}
	| postfix_expression PTR_OP IDENTIFIER {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, makeleaf($3), "", 1);
		$$ = makenode($2, attr);
	}
	| postfix_expression INC_OP {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		$$ = makenode($2, attr);
	}
	| postfix_expression DEC_OP {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		$$ = makenode($2, attr);
	}
	;

argument_expression_list
	: assignment_expression {
		$$ = $1;
	}
	| argument_expression_list ',' assignment_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("argument_list", attr);
	}
	;

unary_expression
	: postfix_expression {
		$$ = $1;
	}
	| INC_OP unary_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $2, "", 1);
		$$ = makenode($1,attr);
	}
	| DEC_OP unary_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $2, "", 1);
		$$ = makenode($1,attr);
	}
	| unary_operator cast_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $2, "", 1);
		$$ = makenode("unary_exp",attr);
	}
	| SIZEOF unary_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $2, "", 1);
		$$ = makenode($1,attr);
	}
	| SIZEOF '(' type_name ')' {
		vector<data> attr = createVector();
		insertAttr(attr, $3, "", 1);
		$$ = makenode($1,attr);
	}
	;

unary_operator
	: '&' {
		$$ = makeleaf("&");
	}
	| '*' {
		$$ = makeleaf("*");
	}
	| '+' {
		$$ = makeleaf("+");
	}
	| '-' {
		$$ = makeleaf("-");
	}
	| '~' {
		$$ = makeleaf("~");
	}
	| '!' {
		$$ = makeleaf("!");
	}
	;

cast_expression
	: unary_expression {
		$$ = $1;
	}
	| '(' type_name ')' cast_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $2, "", 1);
		insertAttr(attr, $4, "", 1);
		$$ = makenode("cast_expression" ,attr);
	}
	;

multiplicative_expression
	: cast_expression {
		$$ = $1;
	}
	| multiplicative_expression '*' cast_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("*" ,attr);
	}
	| multiplicative_expression '/' cast_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("/" ,attr);
	}
	| multiplicative_expression '%' cast_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("%" ,attr);
	}
	;

additive_expression
	: multiplicative_expression {
		$$ = $1;
	}
	| additive_expression '+' multiplicative_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("+" ,attr);
	}
	| additive_expression '-' multiplicative_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("-" ,attr);
	}
	;

shift_expression
	: additive_expression {
		$$ = $1;
	}
	| shift_expression LEFT_OP additive_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);
	}
	| shift_expression RIGHT_OP additive_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);
	}
	; 

relational_expression
	: shift_expression {
		$$ = $1;
	}
	| relational_expression '<' shift_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("<" ,attr);
	}
	| relational_expression '>' shift_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode(">" ,attr);
	}
	| relational_expression LE_OP shift_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);
	}
	| relational_expression GE_OP shift_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);
	}
	;

equality_expression
	: relational_expression {
		$$ = $1;
	}
	| equality_expression EQ_OP relational_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);
	}
	| equality_expression NE_OP relational_expression {
		vector<data> attr = createVector();
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);
	}
	;

and_expression
	: equality_expression												{$$ = $1;}
	| and_expression '&' equality_expression 							{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			$$ = makenode("&",attr);
																		}
	;

exclusive_or_expression
	: and_expression													{$$ = $1;}
	| exclusive_or_expression '^' and_expression 						{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			$$ = makenode("^",attr);
																		}
	;

inclusive_or_expression
	: exclusive_or_expression											{$$ = $1;}
	| inclusive_or_expression '|' exclusive_or_expression				{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			$$ = makenode("|",attr);
																		}
	;

logical_and_expression
	: inclusive_or_expression											{$$ = $1;}
	| logical_and_expression AND_OP inclusive_or_expression				{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			$$ = makenode("&&",attr);
																		}
	;

logical_or_expression
	: logical_and_expression											{$$ = $1;}
	| logical_or_expression OR_OP logical_and_expression				{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			$$ = makenode("||",attr);
																		}
	;

conditional_expression
	: logical_or_expression												{$$ = $1;}
	| logical_or_expression '?' expression ':' conditional_expression	{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			insertAttr(attr, $5, "", 1);
																			$$ = makenode("ternary operator",attr);
																		}
	;

assignment_expression
	: conditional_expression											{$$ = $1;}
	| unary_expression assignment_operator assignment_expression		{
																			vector<data> attr;
																			insertAttr(attr, $1, "", 1);
																			insertAttr(attr, $3, "", 1);
																			$$ = makenode($2,attr);
																		}
	;

assignment_operator
	: '='				{$$ = "=";}
	| MUL_ASSIGN		{$$ = $1;}
	| DIV_ASSIGN		{$$ = $1;}
	| MOD_ASSIGN		{$$ = $1;}
	| ADD_ASSIGN		{$$ = $1;}
	| SUB_ASSIGN		{$$ = $1;}
	| LEFT_ASSIGN		{$$ = $1;}
	| RIGHT_ASSIGN		{$$ = $1;}
	| AND_ASSIGN		{$$ = $1;}
	| XOR_ASSIGN		{$$ = $1;}
	| OR_ASSIGN			{$$ = $1;}
	;

expression
	: assignment_expression								{$$ = $1;}
	| expression ',' assignment_expression				{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $3, "", 1);
															$$ = makenode("expression",attr);
														}
	;

constant_expression
	: conditional_expression							{$$ = $1;}
	;

declaration
	: declaration_specifiers ';'						{ $$ = $1; }
	| declaration_specifiers init_declarator_list ';'	{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration",attr);
														}
	;

declaration_specifiers
	: storage_class_specifier							{ $$ = $1; }
	| storage_class_specifier declaration_specifiers	{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration_specifiers",attr);
														}
	| type_specifier									{ $$ = $1; }
	| type_specifier declaration_specifiers				{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration_specifiers",attr);
														}
	| type_qualifier									{ $$ = $1; }
	| type_qualifier declaration_specifiers				{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration_specifiers",attr);
														}
	;

init_declarator_list
	: init_declarator									{$$ = $1;}
	| init_declarator_list ',' init_declarator			{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $3, "", 1);
															$$ = makenode("init_declarator_list",attr);
														}
	;

init_declarator
	: declarator	{
		$$ = $1;
	}
	| declarator '=' initializer	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("=", v);
	}
	;

storage_class_specifier
	: TYPEDEF	{
		$$ = makeleaf($1);
	}
	| EXTERN	{
		$$ = makeleaf($1);
	}
	| STATIC	{
		$$ = makeleaf($1);
	}
	| AUTO	{
		$$ = makeleaf($1);
	}
	| REGISTER	{
		$$ = makeleaf($1);
	}
	;

type_specifier
	: VOID		{
		$$ = makeleaf($1);
	}	
	| CHAR		{
		$$ = makeleaf($1);
	}	
	| SHORT		{
		$$ = makeleaf($1);
	}	
	| INT			{
		$$ = makeleaf($1);
	}
	| LONG			{
		$$ = makeleaf($1);
	}
	| FLOAT			{
		$$ = makeleaf($1);
	}
	| DOUBLE		{
		$$ = makeleaf($1);
	}
	| SIGNED		{
		$$ = makeleaf($1);
	}
	| UNSIGNED		{
		$$ = makeleaf($1);
	}
	| struct_or_union_specifier	{
		$$ = $1;
	}	
	| enum_specifier	{
		$$ = $1;
	}
	| TYPE_NAME		{
		$$ = makeleaf($1);
	}	
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'	{
		vector<data> v;
		insertAttr(v, makeleaf($2), "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode($1, v);
	}
	| struct_or_union '{' struct_declaration_list '}'		{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		$$ = makenode($1, v);
	}
	| struct_or_union IDENTIFIER 	{
		vector<data> v;
		insertAttr(v, makeleaf($2), "", 1);
		$$ = makenode($1, v);
	}
	;

struct_or_union
	: STRUCT	{$$ = $1;}
	| UNION		{$$ = $1;}
	;

struct_declaration_list
	: struct_declaration	{ $$ = $1 ;}
	| struct_declaration_list struct_declaration 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("struct_declaration_list", v);
	}
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';' 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("struct_declaration", v);
	}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("specifier_qualifier_list", v);
	}
	| type_specifier	{ $$ = $1; }
	| type_qualifier specifier_qualifier_list 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("specifier_qualifier_list", v);
	}
	| type_qualifier	{ $$ = $1; }
	;

struct_declarator_list
	: struct_declarator { $$ = $1; }
	| struct_declarator_list ',' struct_declarator {
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("struct_declarator_list", v);
	}
	;

struct_declarator
	: declarator	{ $$ = $1; }
	| ':' constant_expression	{ $$ = $2; }
	| declarator ':' constant_expression	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode(":", v);
	}
	;

enum_specifier
	: ENUM '{' enumerator_list '}'		{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		$$ = makenode($1, v);
	}
	| ENUM IDENTIFIER '{' enumerator_list '}'	{
		vector<data> v;
		insertAttr(v, makeleaf($2), "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode($1, v);
	}
	| ENUM IDENTIFIER {
		vector<data> v;
		insertAttr(v, makeleaf($2), "", 1);
		$$ = makenode($1, v);
	}
	;

enumerator_list
	: enumerator 	{ $$ = $1; }
	| enumerator_list ',' enumerator 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("enumerator_list", v);
	}
	;

enumerator
	: IDENTIFIER	{ $$ = makeleaf($1); }
	| IDENTIFIER '=' constant_expression 	{
		vector<data> v;
		insertAttr(v, makeleaf($1), "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("=", v);
	}
	;

type_qualifier
	: CONST		{ $$ = makeleaf($1); }
	| VOLATILE	{ $$ = makeleaf($1); }
	;


declarator
	: pointer direct_declarator{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("declarator", v);
	}
	| direct_declarator {
		$$ = $1 ;
	}
	;


direct_declarator
	: IDENTIFIER {
		$$ = makeleaf($1);
	}
	| '(' declarator ')'  {
		$$ = $2 ;
	}
	| direct_declarator '[' constant_expression ']'{
		vector<data> v, v2;
		insertAttr(v2, $3, "", 1);
		treeNode* node = makenode("[ ]", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_declarator", v);
	}
	| direct_declarator '[' ']'{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, NULL, "[ ]", 0);
		$$ = makenode("direct_declarator", v);
	}
	| direct_declarator '(' parameter_type_list ')'{
		vector<data> v, v2;
		insertAttr(v2, $3, "", 1);
		treeNode* node = makenode("( )", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_declarator", v);
	}
	| direct_declarator '(' identifier_list ')'{
		vector<data> v, v2;
		insertAttr(v2, $3, "", 1);
		treeNode* node = makenode("( )", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_declarator", v);
	}
	| direct_declarator '(' ')'{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, NULL, "( )", 0);
		$$ = makenode("direct_declarator", v);
	}
	;

pointer
	: '*' {
		$$ = makeleaf("*(Pointer)");
	}
	| '*' type_qualifier_list{
		vector<data> v;
		insertAttr(v,$2,"",1);
		$$ = makenode("*(Pointer)",v);
	}
	| '*' pointer{
		vector<data> v;
		insertAttr(v,$2,"",1);
		$$ = makenode("*(Pointer)",v);
	}
	| '*' type_qualifier_list pointer{
		vector<data> v;
		insertAttr(v,$2,"",1);
		insertAttr(v,$3,"",1);
		$$ = makenode("*(Pointer)",v);
	}
	;

type_qualifier_list
	: type_qualifier {
		$$ = $1 ;
	}
	| type_qualifier_list type_qualifier{
		vector<data> v;
		insertAttr(v,$1,"",1);
		insertAttr(v,$2,"",1);
		$$ = makenode("type_qualifier_list",v);
	}
	;


parameter_type_list
	: parameter_list {
		$$ = $1 ;
	}
	| parameter_list ',' ELLIPSIS{
		vector<data> v;
		insertAttr(v,$1,"",1);
		insertAttr(v, makeleaf($3), "", 1);
		$$ = makenode("parameter_type_list",v);
	}
	;

parameter_list
	: parameter_declaration{
		$$ = $1;
	}
	| parameter_list ',' parameter_declaration{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("parameter_list",v);
	}
	;

parameter_declaration
	: declaration_specifiers declarator{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("parameter_declaration",v);
	}
	| declaration_specifiers abstract_declarator{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("parameter_declaration",v);
	}
	| declaration_specifiers {
		$$ = $1;
	}
	;

identifier_list
	: IDENTIFIER {
		$$ =makeleaf($1);
	}
	| identifier_list ',' IDENTIFIER{
		vector<data> v;
		insertAttr(v,$1,"",1);
		insertAttr(v,makeleaf($3),"",1);
		$$ = makenode("identifier_list",v);
	}
	;

type_name
	: specifier_qualifier_list{
		$$ = $1;
	}
	| specifier_qualifier_list abstract_declarator{
		vector<data> v;
		insertAttr(v,$1,"",1);
		insertAttr(v,$2,"",1);
		$$ = makenode("type_name",v);
	}
	;

abstract_declarator
	: pointer {
		$$ =$1;
	}
	| direct_abstract_declarator{
		$$ = $1;
	}
	| pointer direct_abstract_declarator{
		vector<data> v;
		insertAttr(v,$1,"",1);
		insertAttr(v,$2,"",1);
		$$ = makenode("abstract_declarator",v);
	}
	;

direct_abstract_declarator
	: '(' abstract_declarator ')' {
		$$ = $2;
	}
	| '[' ']'{
		$$ = makeleaf("[ ]") ;
	}
	| '[' constant_expression ']' {
		$$ = $2;
	}
	| direct_abstract_declarator '[' ']' {
		vector<data> v;
		insertAttr(v,NULL,"[ ]",0);
		insertAttr(v,$1,"",1);
		$$ = makenode("direct_abstract_declarator",v);
	}
	| direct_abstract_declarator '[' constant_expression ']'{
		vector<data> v, v2;
		insertAttr(v2, $3, NULL, 1);
		treeNode* node = makenode("[ ]", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_abstract_declarator", v);
	}
	| '(' ')'{
		$$ = makeleaf("( )") ;
	}
	| '(' parameter_type_list ')'{
		$$ = $2 ;
	}
	| direct_abstract_declarator '(' ')'{
		vector<data> v;
		insertAttr(v, NULL, "( )", 0);
		insertAttr(v, $1, "", 1);
		$$ = makenode("direct_abstract_declarator",v);
	}
	| direct_abstract_declarator '(' parameter_type_list ')'{
		vector<data> v, v2;
		insertAttr(v2, $3, "", 1);
		treeNode* node = makenode("( )", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_abstract_declarator", v);
	}
	;

initializer
	: assignment_expression{
		$$ = $1 ;
	}
	| '{' initializer_list '}' {
		$$ = $2 ;
	}
	| '{' initializer_list ',' '}'{
		$$ = $2;
	}
	;


initializer_list
	: initializer	{
		$$ = $1;
	}
	| initializer_list ',' initializer	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("initializer_list", v);
	}
	;

statement
	: labeled_statement	{$$ = $1;}
	| compound_statement	{$$ = $1;}
	| expression_statement	{$$ = $1;}
	| selection_statement	{$$ = $1;}
	| iteration_statement	{$$ = $1;}
	| jump_statement	{$$ = $1;}
	;

labeled_statement
	: IDENTIFIER ':' statement	{
		vector<data> v;
		insertAttr(v, makeleaf($1), "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("labeled_statement", v);
	}
	| CASE constant_expression ':' statement	{
		vector<data> v;
		insertAttr(v, $2, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("case", v);
	}
	| DEFAULT ':' statement	{
		vector<data> v;
		insertAttr(v, NULL, "default", 0);
		insertAttr(v, $3, "", 1);
		$$ = makenode("case", v);
	}
	;

compound_statement
	: '{' '}'	{$$ = makeleaf("{ }");}
	| '{' statement_list '}'	{$$ = $2;}
	| '{' declaration_list '}'	{$$ = $2;}
	| '{' declaration_list statement_list '}'	{
		vector<data> v;
		insertAttr(v, $2, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("compound_statement", v);
	}
	;

declaration_list
	: declaration	{$$ = $1;}
	| declaration_list declaration	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("declaration_list", v);
	}
	;

statement_list
	: statement	{$$ = $1;}
	| statement_list statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("statement_list", v);
	}
	;

expression_statement
	: ';'	{$$ = makeleaf(";");}
	| expression ';'	{$$ = $1;}
	;

selection_statement
	: IF '(' expression ')' statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("if", v);
	}
	| IF '(' expression ')' statement ELSE statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		insertAttr(v, $7, "", 1);
		$$ = makenode("if-else", v);
	}
	| SWITCH '(' expression ')' statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("switch", v);
	}
	;

iteration_statement
	: WHILE '(' expression ')' statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("while-loop", v);
	}
	| DO statement WHILE '(' expression ')' ';'	{
		vector<data> v;
		insertAttr(v, $2, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("do-while-loop", v);
	}
	| FOR '(' expression_statement expression_statement ')' statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $4, "", 1);
		insertAttr(v, $6, "", 1);
		$$ = makenode("for-loop(w/o update stmt)", v);
	}
	| FOR '(' expression_statement expression_statement expression ')' statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $4, "", 1);
		insertAttr(v, $5, "", 1);
		insertAttr(v, $7, "", 1);
		$$ = makenode("for-loop", v);
	}
	;

		 
jump_statement
	: GOTO IDENTIFIER ';'	{
		string s;
		s = (string)$1 + " : " + (string)$2;
        $$ = makeleaf(s);
	}
	| CONTINUE ';'	{$$ = makeleaf($1);}
	| BREAK ';'		{$$ = makeleaf($1);}
	| RETURN ';'	{$$ = makeleaf($1);}
	| RETURN expression ';'	{
		vector<data> v;
		insertAttr(v, makeleaf($1), "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("jump_stmt", v);
	}
	;

translation_unit
	: external_declaration	{
		$$ = $1;
	}
	| translation_unit external_declaration	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("program", v);
	}
	;

external_declaration
	: function_definition	{ $$ = $1;}
	| declaration	{ $$ = $1;}
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		insertAttr(v, $3, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("function", v);
	}
	| declaration_specifiers declarator compound_statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("function (w/o decl_list)", v);
	}
	| declarator declaration_list compound_statement	{
		vector<data> v;
                insertAttr(v, $1, "", 1);
                insertAttr(v, $2, "", 1);
                insertAttr(v, $3, "", 1);
                $$ = makenode("function (w/o decl_specifiers)", v);
	}
	| declarator compound_statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("function (w/o specifiers and decl_list)", v);
	}
	;

%%

void print_options(){
	// To be constructed later
	cout<<"\t--help\t\t\tDisplay available options\n";

	cout<<"\n\n";
}

void no_file_present(){
	cout<<"Error: no input files\nCompilation terminated\n";
}


int main(int argc, char* argv[]){
	
	char* file_name = "graph.dot";
	int file_present = 0;

	if(argc <= 1){
		no_file_present();
		return -1;
	}
	
	for(int i = 1; i<argc; i++){
		if(!strcmp(argv[i], "--help")){
			print_options();
			return 0;
		}
	}

	for(int i = 1; i<argc; i++){
		if(!strcmp(argv[i], "-o")){
			if(i+1 >= argc || argv[i+1][0] == '-'){
				cout<<"Error: missing filename after \'-o\'\nCompilation terminated\n";
				return -1;
			}
			else{
				file_name = argv[i+1];
				i++;
			}
		}
		else if(argv[i][0] != '-') file_present++;
	}

	if(!file_present){
		no_file_present();
		return -1;
	}

	dotfile = fopen(file_name, "w");
	
	if(dotfile == NULL){
		cout<<"Error: cannot open the dot file "<<file_name<<"\nCompilation terminated\n";
		return -1;
	}

	beginAST();
	

	for(int i = 1; i<argc; i++){
		if(!strcmp(argv[i], "-o")){
			i++;
			continue;
		}

		yyin = fopen(argv[i], "r");
		
		// File open failed, proceeding to next file(s), if exist
		if(yyin == NULL){
			cout<<"Error: cannot open file "<<argv[i]<<"\n\n";
			continue;
		}
		
		yyrestart(yyin);
		yyparse();
	}

	endAST();

	return 0;
}

int yyerror(char *s) { 
	printf("ERROR: %s in [%s] on line# %d column# %d\n", s, yytext, line, column+1);
  	return 0;
}
