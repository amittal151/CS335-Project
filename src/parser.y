%{
#include <stdio.h>
#include <iostream>
#include "AST.h"
#include "codegen.h"
#include <fstream>

extern char* yytext;
extern int column;
extern int line;
extern vector<quad> code;
int yyerror(const char*);
int warning(const char*);
int yylex();
int only_lexer = 0;
FILE* dotfile;
FILE* lexer_file;
ofstream code_file;
char* curr_file;

string funcName = "";
string structName = "";
string funcType = "";
int block_count = 0;
stack<int> block_stack;
bool fn_decl = 0;
int func_flag = 0;

string type = "";
int Anon_StructCounter=0;
vector<string> funcArgs;
vector<string> idList;
vector<vector<string> > currArgs(1,vector<string>() );

int if_found = 0;
map<string, vector<int>> gotolablelist;
map<string, int> gotolabel;


extern int yylex();
extern int yyrestart(FILE*);
extern FILE* yyin;
extern char* last;
extern int yylineno;
extern void print3AC_code();
#define YYERROR_VERBOSE
%}

%union{
	char* str;
	treeNode* ptr;
	constants* num;
	int ind;
}

// %define parse.error detailed
%token-table 
%token<str> IDENTIFIER STRING_LITERAL SIZEOF
%token<str> PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token<str> AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token<str> SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token<str> XOR_ASSIGN OR_ASSIGN TYPE_NAME
%token<num> CONSTANT

%token<str> TYPEDEF EXTERN STATIC AUTO REGISTER
%token<str> CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token<str> STRUCT UNION ENUM ELLIPSIS
%token<str> CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%start translation_unit

%type<str> G 
%type<str> CHANGE_TABLE 
%type<ind> NEXT_QUAD WRITE_GOTO
%type<ptr> primary_expression postfix_expression argument_expression_list unary_expression unary_operator cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression
%type<str> assignment_operator 
%type<ptr> and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression 
%type<ptr> assignment_expression expression constant_expression declaration declaration_specifiers init_declarator_list
%type<ptr> declarator direct_declarator pointer type_qualifier_list parameter_type_list parameter_list parameter_declaration identifier_list type_name abstract_declarator direct_abstract_declarator initializer
%type<ptr> init_declarator type_specifier struct_or_union_specifier	struct_declaration_list struct_declaration specifier_qualifier_list struct_declarator_list struct_declarator enum_specifier enumerator_list enumerator type_qualifier
%type<ptr> statement labeled_statement compound_statement declaration_list statement_list expression_statement selection_statement iteration_statement jump_statement translation_unit external_declaration function_definition initializer_list
%type<ptr> storage_class_specifier GOTO_AND GOTO_COND GOTO_OR CASE_CODE IF_CODE EXPR_CODE EXPR_STMT_CODE 
%type<ptr> N S F
%type<str> struct_or_union

%left '+' '-' '*' '/' '%' ">>" "<<" "++" "--" "==" "!=" 
%left '&' '|' '^' "&&" "||" ',' ';' 
%right '=' "+=" "-=" "*=" "/=" "%=" "<<=" ">>=" "&=" "^=" "|="

%%
primary_expression
    : IDENTIFIER {
    	$$ = makeleaf($1);
		
		// Semantics
		string temp = primaryExpression(string($1));
		if(temp == ""){
			yyerror(("Undeclared Identifier " + string($1)).c_str());
			$$->is_error = 1;
		}
		else{
			if(temp.substr(0, 5) == "FUNC_"){
				$$->expType = 3;
			}
			else if(temp.back() == '*'){
				$$->expType = 2; 
			}
			else $$->expType = 1;

			$$->type = temp;
			$$->isInit = lookup(string($1))->init;
			$$->size = getSize(temp);
			$$->temp_name = string($1); 
			
			//--3AC
			$$->place = qid(string($1), lookup(string($1)));
			$$->nextlist.clear();
		}
    }
	| CONSTANT {
		$$ = makeleaf($1->str);
		$$->type = $1->type;
		$$->intVal = $1->intVal;
		$$->realVal = $1->realVal;
		$$->expType = 4;
		$$->temp_name = $1->str;

		//--3AC
		sym_entry* temp = new sym_entry;
		$$->place = qid(($1->str), temp);
		$$->nextlist.clear();

	}
	| STRING_LITERAL {
		$$ = makeleaf($1);
		$$->type = string("char*");
		$$->temp_name = string($1);
		$$->strVal = string($1);


		//--3AC
		$$->place = qid($1, NULL);
		$$->nextlist.clear();

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
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("postfix_expression", attr);

		//Semantics
		if($1->isInit && $3->isInit){
			$$->isInit = 1;
		}
		string temp = postfixExpression($1->type,1);
		if(!($1->is_error || $3->is_error)){
			if(!temp.empty()){	
				$$->type = temp;

				//--3AC
				$$->place = newtemp(temp);
				if($3->place.second) $$->place.second->offset = $1->place.second->offset;
				if($3->place.second) $$->place.second->size = $3->place.second->offset;
				
				//TODO (is_init);

				$$->nextlist.clear();

			}
			else{
				yyerror(("Array " + $1->temp_name +  " Index out of bound").c_str());
				$$->is_error=1;
			}
		}
		else{
			$$->is_error=1;
		}
	}
	| postfix_expression '(' ')' {
		$$ = $1;

		//Semantics
		$$->isInit = 1;
		string temp = postfixExpression($1->type,2);
		currArgs.push_back(vector<string>() ); 
		if(!($1->is_error)){
			if(!temp.empty()){	
				$$->type = temp;
				if($1->expType == 3){
					vector<string> funcArg = getFuncArgs($1->temp_name);
					if(!funcArg.empty()){
						yyerror(("Too few Arguments to Function " + $1->temp_name).c_str());
					}
					else{

					//--3AC

						qid q = newtemp(temp);
						$$->nextlist.clear();

						// emit(qid("refParam", NULL), , NULL)qid("", qid("", NULL), q, -1);
						emit(qid("CALL", NULL), $1->place, qid("1", NULL), q, -1);
						currArgs.pop_back();
						//if(currArgs.size()>1)currArgs.back().push_back($$->type) ;
						$$->place = q;
					}
				}
			}
			else{
				yyerror(("Function " + $1->temp_name + " not declared in this scope").c_str());
				$$->is_error=1;
			}
		}
		else{
			$$->is_error=1;
		}
		//currArgs.clear(); 
	}
	| postfix_expression  '(' { currArgs.push_back(vector<string>() ); } argument_expression_list ')' {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $4, "", 1);
		$$ = makenode("postfix_expression", attr);

		//Semantics
		$$->isInit = $4->isInit;
		string temp = postfixExpression($1->type,3);

		if(!($1->is_error || $4->is_error)){
			if(!temp.empty()){	
				$$->type = temp;
				if($1->expType ==3){
					vector<string> funcArgs = getFuncArgs($1->temp_name);
					vector<string> tempArgs =currArgs.back();
					for(int i=0;i<tempArgs.size();i++)cout<<tempArgs[i]<<", ";
					cout<<"\n";
					for(int i=0;i<funcArgs.size();i++){
						if(funcArgs[i]=="...")break;
						if(tempArgs.size()==i){
							
							yyerror(("Too few Arguments to Function " + $1->temp_name).c_str());
							break;
						}
						string msg = checkType(funcArgs[i],tempArgs[i]);

						if(msg =="warning"){
							warning(("Incompatible conversion of " +  tempArgs[i] + " to parameter of type " + funcArgs[i]).c_str());
						}
						else if(msg.empty()){
							yyerror(("Incompatible Argument to the function " + $1->temp_name).c_str());
							break;
						}
						if(i==funcArgs.size()-1 && i<tempArgs.size()-1){
							yyerror(("Too many Arguments to Function " + $1->temp_name).c_str());
							break;
						}

					}	


					//--3AC

					qid q = newtemp($$->type);
					$$->place = q;
					$$->nextlist.clear();

					// emit(qid("refParam", NULL), qid("", NULL), qid("", NULL), q, -1);
					emit(qid("CALL", NULL), $1->place, qid(to_string(currArgs.back().size()), NULL), q, -1);
					currArgs.pop_back();
					//if(currArgs.size()>1)currArgs.back().push_back($$->type) ;
					//DOUBT size() or size()+1?

				}
			}
			else{
				yyerror("Invalid function call");
				$$->is_error=1;
			}
		}
		else{
			$$->is_error=1;
		}
		
	}
	| postfix_expression '.' IDENTIFIER {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, makeleaf($3), "", 1);
		$$ = makenode("expression.id", attr);

		//Semantics

		if(!$1->is_error){
			string temp = string($3);
			int ret = findTypeAttr($1->type,temp);
			if(ret == -1){
				yyerror(("Struct " + $1->node_name + " not defined").c_str());
				$$->is_error = 1;
			}
			else if (ret == 0){
				yyerror(("Struct " + $1->type.substr(7, $1->type.length()-7) + " has no member " + string($3)).c_str());
				$$->is_error = 1;
			}
			else{
				$$->type = StructAttrType($1->type,temp);
				$$->temp_name = $1->temp_name + "." + temp;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| postfix_expression PTR_OP IDENTIFIER {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, makeleaf($3), "", 1);
		$$ = makenode($2, attr);

		//Semantics
		if(!$1->is_error){
			string temp = string($3);
			string temp1 = ($1->type);
			if(temp1.back() != '*'){
				yyerror(( $1->node_name + " is not a pointer, did you mean to use '.' ").c_str());
				$$->is_error=1;
			}
			else{

				temp1.pop_back();
				int ret = findTypeAttr(temp1, temp);
				if(ret ==-1){
					yyerror("Struct not defined");
					$$->is_error=1;
				}
				else if (ret == 0){
					yyerror("Attribute of Struct not defined");
					$$->is_error=1;
				}
				else{
					$$->type = StructAttrType(temp1, temp);
					$$->temp_name = $1->temp_name + "->" + temp;
				}
			}
		}
		else{
			$$->is_error=1;
		}

	}
	| postfix_expression INC_OP {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		$$ = makenode($2, attr);

		//Semantics
		$$->isInit = $1->isInit;
		if(!$1->is_error){
			string temp = postfixExpression($1->type,6);
			if(!temp.empty()){
				$$->type = temp;
				$$->intVal = $1->intVal + 1;


				//--3AC

				qid q = newtemp(temp);
				$$->place = q;
				$$->nextlist.clear();
				emit(qid("++S", lookup("++")), $1->place, qid("", NULL), q, -1);
				// emit(qid("=", lookup("=")), q, qid("", NULL), $1->place, -1);
			}
			else{
				yyerror("Increment not defined for this type");
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}

	}
	| postfix_expression DEC_OP {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		$$ = makenode($2, attr);

		//Semantics
		if(!$1->is_error){
			$$->isInit = $1->isInit;
			string temp = postfixExpression($1->type,7);
			if(!temp.empty()){
				$$->type = temp;
				$$->intVal = $1->intVal - 1;


				//--3AC

				qid q = newtemp(temp);
				$$->place = q;
				$$->nextlist.clear();
				emit(qid("--S", lookup("--")), $1->place, qid("", NULL), q, -1);

			}
			else{
				yyerror("Decrement not defined for this type");
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;




argument_expression_list
	: assignment_expression {
		$$ = $1;

		if(!$1->is_error){
			//Semantic
			$$->isInit = $1->isInit;
			currArgs.back().push_back($1->type);
			$$->type = "void";

			//--3AC
			$$->nextlist.clear();
			int _idx = -1;
			if($$->type == "char*" && $$->place.second == NULL) _idx = -4;
			emit(qid("param", NULL), $$->place, qid("", NULL), qid("", NULL), _idx);
		}
		else{
			$$->is_error = 1;
		}
	}
	| argument_expression_list ',' assignment_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("argument_list", attr);

		//Semantic
		if(!($1->is_error || $3->is_error)){
			string temp = argExp($1->type, $3->type, 2);

			if($1->isInit && $3->isInit) $$->isInit=1;
			currArgs.back().push_back($3->type);
			$$->type = "void";

			//--3AC
			$$->nextlist.clear();
			int _idx = -1;
			if($3->type == "char*" && $3->place.second == NULL) _idx = -4;
			emit(qid("param", NULL), $3->place, qid("", NULL), qid("", NULL), _idx);
		}
		else{
			$$->is_error = 1;
		}
	}
	;


unary_expression
	: postfix_expression {
		$$ = $1;
	}
	| INC_OP unary_expression {
		vector<data> attr;
		insertAttr(attr, $2, "", 1);
		$$ = makenode($1,attr);

		//Semantic
		if(!$2->is_error){
			$$->isInit = $2->isInit;
			string temp = postfixExpression($2->type,6);
			if(!temp.empty()){
				$$->type = temp;
				$$->intVal = $2->intVal +1;

				//--3AC
				qid q = newtemp(temp);
				$$->place = q;
				$$->nextlist.clear();
				emit(qid("++P", lookup("++")), $2->place, qid("", NULL), q, -1);

			}
			else{
				//TODO
				yyerror("Increment not defined for this type");
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| DEC_OP unary_expression {
		vector<data> attr;
		insertAttr(attr, $2, "", 1);
		$$ = makenode($1,attr);

		//Semantic
		if(!$2->is_error){
			$$->isInit = $2->isInit;
			string temp = postfixExpression($2->type,7);
			if(!temp.empty()){
				$$->type = temp;
				$$->intVal = $2->intVal -1;

				//--3AC
				qid q = newtemp(temp);
				$$->place = q;
				$$->nextlist.clear();
				emit(qid("--P", lookup("--")), $2->place, qid("", NULL), q, -1);

			}
			else{
				//TODO
				yyerror("Decrement not defined for this type");
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| unary_operator cast_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $2, "", 1);
		$$ = makenode("unary_exp",attr);

		//Semantic
		if(!($1->is_error || $2->is_error)){
			$$->isInit = $2->isInit;
			string temp = unaryExp($1->node_name,$2->type);
			if(!temp.empty()){
				$$->type = temp;
				$$->intVal = $2->intVal;

				//--3AC
				qid q = newtemp(temp);
				$$->place = q;
				$$->nextlist.clear();
				emit($1->place, $2->place, qid("", NULL), q, -1);

			}
			else{
				//TODO
				yyerror("Type inconsistent with operator");
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| SIZEOF unary_expression {
		vector<data> attr;
		insertAttr(attr, $2, "", 1);
		$$ = makenode($1,attr);

		if(!$2->is_error){
			//Semantic
			$$->type = "int";
			$$->isInit =1;
			$$->intVal = $2->size;

			//--3AC
			qid q = newtemp("int");
			$$->place = q;
			$$->nextlist.clear();
			emit(qid("SIZEOF", lookup("sizeof")), $2->place, qid("", NULL), q, -1);
		}
		else{
			$$->is_error = 1;
		}

	}
	| SIZEOF '(' type_name ')' {
		vector<data> attr;
		insertAttr(attr, $3, "", 1);
		$$ = makenode($1,attr);

		if(!$3->is_error){
			//Semantic
			$$->type = "int";
			$$->isInit =1;
			$$->intVal = $3->size;

			//--3AC
			qid q = newtemp("int");
			$$->place = q;
			$$->nextlist.clear();
			emit(qid("SIZEOF", lookup("sizeof")), $3->place, qid("", NULL), q, -1);
		}
		else{
			$$->is_error = 1;
		}
	}
	;

unary_operator
	: '&' {
		$$ = makeleaf("&");

		//--3AC
		$$->place = qid("unary&", lookup("&"));
	}
	| '*' {
		$$ = makeleaf("*");

		//--3AC
		$$->place = qid("unary*", lookup("*"));
	}
	| '+' {
		$$ = makeleaf("+");

		//--3AC
		$$->place = qid("unary+", lookup("+"));

	}
	| '-' {
		$$ = makeleaf("-");

		//--3AC
		$$->place = qid("unary-", lookup("-"));
	}
	| '~' {
		$$ = makeleaf("~");

		//--3AC
		$$->place = qid("~", lookup("~"));
	}
	| '!' {
		$$ = makeleaf("!");

		//--3AC
		$$->place = qid("!", lookup("!"));
	}
	;

cast_expression
	: unary_expression {
		$$ = $1;
	}
	| '(' type_name ')' cast_expression {
		vector<data> attr;
		insertAttr(attr, $2, "", 1);
		insertAttr(attr, $4, "", 1);
		$$ = makenode("cast_expression" ,attr);

		if(!($2->is_error || $4->is_error)){
			//Semantic
			$$->type = $2->type;
			$$->isInit = $4->isInit;

			//--3AC
			qid q = newtemp($$->type);
			$$->place = q;
			$4->nextlist.clear();
			emit(qid($4->type+"to"+$$->type, NULL), $4->place, qid("", NULL), q, -1);
		}
		else{
			$$->is_error = 1;
		}


	}
	;

multiplicative_expression
	: cast_expression {
		$$ = $1;
	}
	| multiplicative_expression '*' cast_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("*" ,attr);


		if(!($1->is_error || $3->is_error)){

			//Semantic
			$$->intVal = $1->intVal * $3->intVal; 

			//TODO for real
			if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
			string temp = mulExp($1->type, $3->type, '*');

			if(!temp.empty()){
				if(temp == "int"){
					$$->type = "long long" ;

					//--3AC
					qid q = newtemp("long long");
					$$->place = q;
					$$->nextlist.clear();
					emit(qid("*int", lookup("*")), $1->place, $3->place, q, -1);
				}
				else if(temp == "float"){
					$$->type = "long double";

					//--3AC

					qid q = newtemp("long double");
					$$->place = q;
					$$->nextlist.clear();

					if(isInt($1->type)){
						qid q1 = newtemp($$->type);
						emit(qid("inttoreal", NULL), $1->place, qid("", NULL), q1, -1);

						emit(qid("*real", lookup("*")), q1, $3->place, q, -1);
					}
					else if(isInt($3->type)){
						qid q1 = newtemp($$->type);
						emit(qid("inttoreal", NULL), $3->place, qid("", NULL), q1, -1);

						emit(qid("*real", lookup("*")), $1->place, q1, q, -1);
					}
					else{
						emit(qid("*real", lookup("*")), $1->place, $3->place, q, -1);
					}

				}

			}
			else{
				yyerror(("Incompatible types \'" + $1->type + "\' and \'" + $3->type + "\' for * operator").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}

	}
	| multiplicative_expression '/' cast_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("/" ,attr);



		if(!($1->is_error || $3->is_error)){
			//Semantic
			if($3->intVal!=0)$$->intVal = $1->intVal / $3->intVal;
			if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
			string temp =mulExp($1->type,$3->type,'/');
			if(!temp.empty()){
				if(temp == "int"){
					$$->type = "long long" ;

					//--3AC
					qid q = newtemp("long long");
					$$->place = q;
					$$->nextlist.clear();
					emit(qid("/int", lookup("/")), $1->place, $3->place, q, -1);
				}
				else if(temp == "float"){
					$$->type = "long double";

					//--3AC

					qid q = newtemp("long double");
					$$->place = q;
					$$->nextlist.clear();

					if(isInt($1->type)){
						qid q1 = newtemp($$->type);
						emit(qid("inttoreal", NULL), $1->place, qid("", NULL), q1, -1);

						emit(qid("/real", lookup("/")), q1, $3->place, q, -1);
					}
					else if(isInt($3->type)){
						qid q1 = newtemp($$->type);
						emit(qid("inttoreal", NULL), $3->place, qid("", NULL), q1, -1);

						emit(qid("/real", lookup("/")), $1->place, q1, q, -1);
					}
					else{
						emit(qid("/real", lookup("/")), $1->place, $3->place, q, -1);
					}
				}

			}
			else{
				yyerror(("Incompatible types \'" + $1->type + "\' and \'" + $3->type + "\' for / operator").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| multiplicative_expression '%' cast_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("%" ,attr);

		if(!($1->is_error || $3->is_error)){
			//Semantic
			if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
			if($3->intVal!=0)$$->intVal = $1->intVal % $3->intVal;
			string temp =mulExp($1->type,$3->type,'%');
			if(temp == "int"){
				$$->type = "long long" ;

				//--3AC
				qid q = newtemp("long long");
				$$->place = q;
				$$->nextlist.clear();
				emit(qid("%", lookup("%")), $1->place, $3->place, q, -1);

			}
			else{
				yyerror(("Incompatible types \'" + $1->type + "\' and \'" + $3->type + "\' for % operator").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}

	}
	;


additive_expression
	: multiplicative_expression {
		$$ = $1;
	}
	| additive_expression '+' multiplicative_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("+" ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		
		string temp = addExp($1->type,$3->type,'+');
		
		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp == "int")	$$->type = "long long";
				else if(temp == "real")	$$->type = "long double";
				else $$->type =  temp;

				$$->intVal = $1->intVal + $3->intVal;
				$$->realVal = $1->realVal + $3->realVal;
				$$->temp_name = $1->temp_name + " + " + $3->temp_name;

				// 3AC
				qid temp1 = newtemp($$->type);
				int cond1 = (isInt($1->type) && isFloat($3->type));
				int cond2 = (isInt($3->type) && isFloat($1->type));

				if(cond1){
					qid temp2 = newtemp($3->type);
					emit(qid("inttoreal", NULL), $1->place, qid("", NULL), temp2, -1);
					emit(qid("+"+temp, lookup("+")), temp2, $3->place, temp1, -1);
				}
				else if(cond2){
					qid temp2 = newtemp($1->type);
					emit(qid("inttoreal", NULL), $3->place, qid("", NULL), temp2, -1);
					emit(qid("+"+temp, lookup("+")), $1->place, temp2, temp1, -1);
				}
				else{
					emit(qid("+"+temp, lookup("+")), $1->place, $3->place, temp1, -1);
				}

				$$->nextlist.clear();
				$$->place = temp1;
			}
			else{
				//TODO
				yyerror(("Incompatible types \'" + $1->type + "\' and \'" + $3->type + "\' for + operator").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| additive_expression '-' multiplicative_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("-" ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;

		string temp = addExp($1->type,$3->type,'-');
		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp == "int")$$->type = "long long";
				else if(temp == "real")$$->type = "long double";
				else $$->type = temp;

				$$->intVal = $1->intVal - $3->intVal;
				$$->realVal = $1->realVal - $3->realVal;
				$$->temp_name = $1->temp_name + " - " + $3->temp_name;

				// 3AC
				qid temp1 = newtemp($$->type);
				int cond1 = (isInt($1->type) && isFloat($3->type));
				int cond2 = (isInt($3->type) && isFloat($1->type));

				if(cond1){
					qid temp2 = newtemp($3->type);
					emit(qid("inttoreal", NULL), $1->place, qid("", NULL), temp2, -1);
					emit(qid("-"+temp, lookup("-")), temp2, $3->place, temp1, -1);
				}
				else if(cond2){
					qid temp2 = newtemp($1->type);
					emit(qid("inttoreal", NULL), $3->place, qid("", NULL), temp2, -1);
					emit(qid("-"+temp, lookup("-")), $1->place, temp2, temp1, -1);
				}
				else{
					emit(qid("-"+temp, lookup("-")), $1->place, $3->place, temp1, -1);
				}
				
				$$->nextlist.clear();
				$$->place = temp1;
			}
			else{
				//TODO
				yyerror(("Incompatible types \'" + $1->type + "\' and \'" + $3->type + "\' for - operator").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;

shift_expression
	: additive_expression {
		$$ = $1;
	}
	| shift_expression LEFT_OP additive_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);

		//Semantic
		if(!$1->is_error && !$3->is_error){
			if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
			string temp = shiftExp($1->type,$3->type);
			if(!temp.empty()){
				$$->type = $1->type;

				$$->intVal = $1->intVal << $3->intVal;
				$$->temp_name = $1->temp_name + " << " + $3->temp_name;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("<<", lookup("<<")), $1->place, $3->place, temp1, -1);
				
				$$->nextlist.clear();
				$$->place = temp1;
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary <<").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}

	}
	| shift_expression RIGHT_OP additive_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = shiftExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				$$->type = $1->type;

				$$->intVal = $1->intVal >> $3->intVal;
				$$->temp_name = $1->temp_name + " >> " + $3->temp_name;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid(">>", lookup(">>")), $1->place, $3->place, temp1, -1);
				
				$$->nextlist.clear();
				$$->place = temp1;
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary >>").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	; 

relational_expression
	: shift_expression {
		$$ = $1;
	}
	| relational_expression '<' shift_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("<" ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = relExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp == "bool"){
					$$->type = "int";
				}
				else if(temp == "Bool"){
					$$->type = "int";
					 warning("Comparison between pointer and integer");
				}

				if($1->intVal < $3->intVal) $$->intVal = 1;
				else $$->intVal = 0;


				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("<", lookup("<")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary <").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}


	}
	| relational_expression '>' shift_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode(">" ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = relExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp == "bool"){
					$$->type = "int";
				}
				else if(temp == "Bool"){
					$$->type = "int";
					 warning("Comparison between pointer and integer");
				}

				if($1->intVal > $3->intVal) $$->intVal = 1;
				else $$->intVal = 0;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid(">", lookup(">")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary >").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| relational_expression LE_OP shift_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = relExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp == "bool"){
					$$->type = "int";
				}
				else if(temp == "Bool"){
					$$->type = "int";
					 warning("Comparison between pointer and integer");
				}

				if($1->intVal <= $3->intVal) $$->intVal = 1;
				else $$->intVal = 0;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("<=", lookup("<=")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary <=").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| relational_expression GE_OP shift_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);

		//Semantic
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = relExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp == "bool"){
					$$->type = "int";
				}
				else if(temp == "Bool"){
					$$->type = "int";
					 warning("Comparison between pointer and integer");
				}

				if($1->intVal >= $3->intVal) $$->intVal = 1;
				else $$->intVal = 0;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid(">=", lookup(">=")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary >=").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;

equality_expression
	: relational_expression {
		$$ = $1;
	}
	| equality_expression EQ_OP relational_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);

		//Semantics
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = eqExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp =="ok"){
					warning("Comparison between pointer and integer");
				}
				$$->type = "int";

				if($1->intVal == $3->intVal) $$->intVal = 1;
				else $$->intVal = 0;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("==", lookup("==")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
				
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary ==").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	| equality_expression NE_OP relational_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode($2 ,attr);

		//Semantics
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = eqExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp =="ok"){
					warning("Comparison between pointer and integer");
				}
				$$->type = "int";

				if($1->intVal != $3->intVal) $$->intVal = 1;
				else $$->intVal = 0;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("!=", lookup("!=")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
				
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary !=").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;

and_expression
	: equality_expression		{$$ = $1;}
	| and_expression '&' equality_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("&",attr);
		
		//Semantics
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = bitExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp =="ok"){
					$$->type = "int";
				}
				else $$->type = "long long";
				
				$$->intVal = $1->intVal & $3->intVal;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("&", lookup("&")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary &").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;

exclusive_or_expression
	: and_expression	{$$ = $1;}
	| exclusive_or_expression '^' and_expression 	{
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("^",attr);

		//Semantics
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = bitExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp =="ok"){
					$$->type = "int";
				}
				else $$->type = "long long";

				$$->intVal = $1->intVal ^ $3->intVal;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("^", lookup("^")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 
				
			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary ^").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;


inclusive_or_expression
	: exclusive_or_expression	{$$ = $1;}
	| inclusive_or_expression '|' exclusive_or_expression	{
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("|",attr);
	

	//Semantics
		if($1->isInit ==1 && $3->isInit ==1) $$->isInit = 1;
		string temp = bitExp($1->type,$3->type);

		if(!$1->is_error && !$3->is_error){
			if(!temp.empty()){
				if(temp =="ok"){
					$$->type = "int";
				}
				else $$->type = "long long";
				
				$$->intVal = $1->intVal | $3->intVal;

				// 3AC
				qid temp1 = newtemp($$->type);
				emit(qid("|", lookup("|")), $1->place, $3->place, temp1, -1);
				$$->nextlist.clear();
				$$->place = temp1; 

			}
			else{
				yyerror(("Invalid operands of types \'" + $1->type + "\' and \'" + $3->type + "\' to binary |").c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;


logical_and_expression
	: inclusive_or_expression	{$$ = $1;}
	| GOTO_AND NEXT_QUAD inclusive_or_expression	{
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("&&",attr);

		// Semantics
		if(!$1->is_error && !$3->is_error){
			$$->type = string("int");
			$$->isInit = (($1->isInit) & ($3->isInit));   
			$$->intVal = $1->intVal && $3->intVal;

			// 3AC
			if($3->truelist.empty() && if_found){
				emit(qid("GOTO", lookup("goto")), qid("IF", lookup("if")), $3->place, qid("", NULL), 0);
				$3->truelist.push_back(code.size()-1);
				emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
				$3->falselist.push_back(code.size()-1);
			}
			else {
				qid tmp = newtemp($$->type);
				emit(qid("&&", lookup("&&")), $1->place, $3->place, tmp, -1);
				$$->place = tmp;
			}

			backpatch($1->truelist, $2);
			$$->truelist = $3->truelist;
			$$->falselist = $1->falselist;
			$$->falselist.insert($$->falselist.end(), $3->falselist.begin(), $3->falselist.end());
		}
		else{
			$$->is_error = 1;
		}
	}
	;

GOTO_AND
	: logical_and_expression AND_OP {
		$$ = $1;
		
		if(!$1->is_error){
			if($1->truelist.empty() && if_found){
				emit(qid("GOTO", lookup("goto")), qid("IF", lookup("if")), $1->place, qid("", NULL), 0);
				$1->truelist.push_back(code.size()-1);
				emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
				$1->falselist.push_back(code.size()-1);
			}
		}
		else $$->is_error = 1;
	}
	;


logical_or_expression
	: logical_and_expression	{$$ = $1;}
	| GOTO_OR NEXT_QUAD logical_and_expression	{
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		$$ = makenode("||",attr);

		// Semantics

		if(!$1->is_error && !$3->is_error){
			$$->type = string("int");
			$$->isInit = (($1->isInit) & ($3->isInit));   
			$$->intVal = $1->intVal || $3->intVal;

			// 3AC

			if($3->truelist.empty() && if_found){
				emit(qid("GOTO", lookup("goto")), qid("IF", lookup("if")), $3->place, qid("", NULL), 0);
				$3->truelist.push_back(code.size()-1);
				emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
				$3->falselist.push_back(code.size()-1);
			}
			else {
				qid tmp = newtemp($$->type);
				emit(qid("||", lookup("||")), $1->place, $3->place, tmp, -1);
				$$->place = tmp;
			}

			backpatch($1->falselist, $2);
			$$->truelist = $1->truelist;
			$$->truelist.insert($$->truelist.end(), $3->truelist.begin(), $3->truelist.end());
			$$->falselist = $3->falselist;
		}
		else{
			$$->is_error = 1;
		}
	}
	;

GOTO_OR
	: logical_or_expression OR_OP {
		$$ = $1;
		if(!$1->is_error){
			if($1->truelist.empty() && if_found){
				emit(qid("GOTO", lookup("goto")), qid("IF", lookup("if")), $1->place, qid("", NULL), 0);
				$1->truelist.push_back(code.size()-1);
				emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
				$1->falselist.push_back(code.size()-1);
			}
		}
		else $$->is_error = 1;
		
	}
	;

conditional_expression
	: logical_or_expression		{$$ = $1;}
	| GOTO_COND NEXT_QUAD expression WRITE_GOTO ':' NEXT_QUAD conditional_expression WRITE_GOTO{
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $3, "", 1);
		insertAttr(attr, $7, "", 1);
		$$ = makenode("ternary operator",attr);

		// Semantics
		string temp = condExp($3->type, $7->type);

		if(!$1->is_error && !$3->is_error && !$7->is_error){
			if(!temp.empty()){
				$$->type = "int";

				if($1->intVal) $$->intVal = $3->intVal;
				else $$->intVal = $7->intVal;
				if($1->isInit==1 && $3->isInit==1 && $7->isInit==1) $$->isInit=1;

				// 3AC
				qid temp1 = newtemp($$->type);

				backpatch($1->truelist, $2);
				backpatch($1->falselist, $6);
				code[$4-1].arg1 = $3->place;
				code[$4-1].res = temp1;

				code[$8-1].arg1 = $7->place;
				code[$8-1].res = temp1;
				
				$$->nextlist = $3->nextlist;
				// ????
				$$->nextlist.insert($$->nextlist.end(), $7->nextlist.begin(), $7->nextlist.end());
				$$->nextlist.push_back($4);
				$$->nextlist.push_back($8);

				$$->place = temp1;
			}
			else {
				yyerror("type mismatch in conditional expression");
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}
	;

GOTO_COND
	: logical_or_expression '?' {
		$$ = $1;
		if(!$1->is_error){
			if($1->truelist.empty()){
				emit(qid("GOTO", lookup("goto")), qid("IF", lookup("if")), $1->place, qid("", NULL), 0);
				$1->truelist.push_back(code.size()-1);
				emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
				$1->falselist.push_back(code.size()-1);
			}
		}
		else $$->is_error = 1;
	}
	;

WRITE_GOTO
	: %empty {
		emit(qid("=", lookup("=")), qid("", NULL), qid("", NULL), qid("", NULL), -1);
		emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
		$$ = code.size()-1;
	}
	;


assignment_expression
	: conditional_expression	{$$ = $1;}
	| unary_expression assignment_operator {if_found = 0;} assignment_expression {
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $4, "", 1);
		$$ = makenode($2,attr);

		//Semantics
		string temp = assignExp($1->type,$4->type,string($2));

		if(!$1->is_error && !$4->is_error){
			if(!temp.empty()){
				if(temp =="ok"){
					$$->type = $1->type;
				}
				else if(temp == "warning"){
					$$->type = $1->type;
					warning("Assignment with incompatible pointer type");
				} 

				if($1->expType == 3 && $4->isInit){
					updInit($1->temp_name);
				}
				
				// 3ac 
				int num = assign_exp($2, $$->type, $1->type, $4->type, $1->place, $4->place);
				$$->place = $1->place;
				backpatch($4->nextlist, num);
			}
			else{
				yyerror(("Incompatible types when assigning " + $4->type + " type to " + $1->type).c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
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


// Abhishek TODO

expression
	: assignment_expression				{ $$ = $1; }
	| expression ',' NEXT_QUAD assignment_expression		{
		vector<data> attr;
		insertAttr(attr, $1, "", 1);
		insertAttr(attr, $4, "", 1);
		$$ = makenode("expression",attr);


		if(!$1->is_error && !$4->is_error){
			$$->type = $1->type;
			// 3AC 
			backpatch($1->nextlist,$3);
			backpatch($1->truelist,$3);
			backpatch($1->falselist,$3);
			$$->nextlist = $4->nextlist;
			$$->place = $4->place;
		}
		else {
			$$->is_error = 1;
		}
	}
	;


constant_expression
	: conditional_expression							{$$ = $1;}
	;

declaration
	: declaration_specifiers ';'						{ $$ = $1;  type = "";}
	| declaration_specifiers init_declarator_list ';'	{	
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration",attr);

															type = "";
															// if($2->expType == 3){
															// 	// Clear the Symbol table of Function;
															// 	// But which function? We need func_name?
															// 	// $2->temp_name
															// 	// if func is already in the FuncArgs Map => Check argument types
															// 	// If argument types dont match, return error!

															// }
															if(!$1->is_error && !$2->is_error){
																// 3AC
																$$->nextlist = $2->nextlist;
															}
															else $$->is_error = 1;
															
														}
	;


declaration_specifiers
	: storage_class_specifier							{ $$ = $1; }
	| storage_class_specifier declaration_specifiers	{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration_specifiers",attr);

															if($1->is_error || $2->is_error) $$->is_error = 1;
														}

	| type_specifier									{ $$ = $1; }
	| type_specifier declaration_specifiers				{	
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration_specifiers",attr);

															if($1->is_error || $2->is_error) $$->is_error = 1;
														}

	| type_qualifier									{ $$ = $1; }
	| type_qualifier declaration_specifiers				{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $2, "", 1);
															$$ = makenode("declaration_specifiers",attr);

															if($1->is_error || $2->is_error) $$->is_error = 1;
														}
	;

init_declarator_list
	: init_declarator									{ $$ = $1;}
	| init_declarator_list ',' NEXT_QUAD init_declarator 
														{
															vector<data> attr;
															insertAttr(attr, $1, "", 1);
															insertAttr(attr, $4, "", 1);
															$$ = makenode("init_declarator_list",attr);
															
															if(!$1->is_error && !$4->is_error){
																// 3AC
																backpatch($1->nextlist, $3);
																$$->nextlist = $4->nextlist;
															}
															else $$->is_error = 1;
														}
	;

init_declarator
	: declarator	{
		$$ = $1;

		// Semantics
		if(!$1->is_error){
			if(currLookup($1->temp_name) ){
				string errstr = $1->temp_name + " is already declared";
				yyerror(errstr.c_str());
				$$->is_error = 1;
			}
			else if($1->expType == 3){
				if(fn_decl){
					yyerror("A parameter list without types is only allowed in a function definition");
					$$->is_error = 1;
					fn_decl = 0;
				}
				removeFuncProto();
				code.pop_back();
			}
			else{
				insertSymbol(*curr_table, $1->temp_name, $1->type, $1->size, 0, NULL);
				$$->place = qid($1->temp_name, lookup($1->temp_name));
			}
		}
		else $$->is_error = 1;
	}
	| declarator '=' NEXT_QUAD initializer	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("=", v);
	
		// Semantics
		if(!$1->is_error && !$4->is_error){
			if( currLookup($1->temp_name) ){
				string errstr = $1->temp_name + " is already declared";
				yyerror(errstr.c_str());
			}
			else{
				insertSymbol(*curr_table, $1->temp_name, $1->type, $1->size, 1, NULL);
			}
			// string a = checkType($1->type, $4->type);
			if(!isVoid($1->type)){
				
				$1->place = qid($1->temp_name, lookup($1->temp_name));
				// TODO
				assign_exp("=", $1->type,$1->type, $4->type, $1->place, $4->place);
				$$->place = $1->place;
				$$->nextlist = $4->nextlist;
				backpatch($1->nextlist, $3);
			}
			else { 
				yyerror(("Invalid assignment to variable of type " + $1->type).c_str()); 
			}
			$$->place = qid($1->node_name, lookup($1->node_name));
		}
		else $$->is_error = 1;
	}
	;

storage_class_specifier
	: TYPEDEF	{
		$$ = makeleaf($1);
		yyerror("Not Implemented TYPEDEF yet!");
		$$->is_error = 1;
	}
	| EXTERN	{
		$$ = makeleaf($1);
		yyerror("Not Implemented EXTERN");
		$$->is_error = 1;
	}
	| STATIC	{
		$$ = makeleaf($1);
		yyerror("Not Implemented STATIC");
		$$->is_error = 1;
	}
	| AUTO	{
		$$ = makeleaf($1);
		yyerror("Not Implemented AUTO");
		$$->is_error = 1;
	}
	| REGISTER	{
		$$ = makeleaf($1);
		yyerror("Not Implemented REGISTER");
		$$->is_error = 1;
	}
	;

type_specifier
	: VOID		{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}	
	| CHAR		{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}	
	| SHORT		{
		$$ = makeleaf($1);
		
		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);	
		$$->type = $1;
	}	
	| INT			{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}
	| LONG			{
		$$ = makeleaf($1);
		
		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}
	| FLOAT			{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}
	| DOUBLE		{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}
	| SIGNED		{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}
	| UNSIGNED		{
		$$ = makeleaf($1);

		// Semantics
		if(type == "") type = string($1);
		else type += " " + string($1);
		$$->type = $1;
	}
	| struct_or_union_specifier	{
		$$ = $1;
	}	
	| enum_specifier	{
		$$ = $1;
		// TODO
	}
	| TYPE_NAME		{
		$$ = makeleaf($1);
		string temp = getType($1);
		type = temp;
	}	
	;

struct_or_union_specifier
	: struct_or_union G S '{' struct_declaration_list '}'	{
		vector<data> v;
		insertAttr(v, makeleaf($2), "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode($1, v);
 
		// Semantics
		if(!$3->is_error && !$5->is_error) {
			if(!currTypeLookup("struct_" + string($2)) && !currTypeLookup("union_" + string($2)) ){
				printStructTable(string($1) + "_" + string($2));
				type = string($1) + "_" + string($2);
				$$->type = type;
			}
			else {
				yyerror(("redefinition of " + string($2)).c_str());
				$$->is_error = 1;
			}
		}
		else{
			$$->is_error = 1;
		}
	}

	| struct_or_union S '{' struct_declaration_list '}'		{
		vector<data> v;
		insertAttr(v, $4, "", 1);
		$$ = makenode($1, v);

		// Semantics
		Anon_StructCounter++;
		if(!$2->is_error && !$4->is_error){
			if(!currTypeLookup("struct_" + to_string(Anon_StructCounter)) && !currTypeLookup("union_" + to_string(Anon_StructCounter)) ){
				printStructTable(string($1) + "_" + to_string(Anon_StructCounter));
				type = string($1) + "_" + to_string(Anon_StructCounter);
				$$->type = type;
			}
			else {
				// Wont come here
				yyerror(("redefinition of " + to_string(Anon_StructCounter)).c_str());
				$$->is_error = 1;
			}
		}
		else {
			$$->is_error = 1;
		}
	}
	| struct_or_union IDENTIFIER {
		vector<data> v;
		insertAttr(v, makeleaf($2), "", 1);
		$$ = makenode($1, v);

		// Semantics

		if(typeLookup(string($1) + "_" + string($2))){
			if(type == ""){
				type = string($1) + "_" + string($2);
				$$->type = type;
			}
			else {
				yyerror(("cannot combine with previous " + type + " declaration specifier").c_str());
				$$->is_error = 1;
			}
		}
		else if(structName == string($2)){
			// We are inside a struct
			structName = string($1) + "_" + structName;
			type = "#INSIDE";
		}
		else {
			yyerror(( string($1) + " " + string($2) + " is not defined").c_str());
			$$->is_error = 1;
		}

	}
	;

G 	
	: IDENTIFIER 	{
		$$ = $1;
		structName = $1;
	}


S 
	: %empty {
		$$ = new treeNode;
		createStructTable();

		if(type != "") {
			yyerror(("cannot combine with previous " + type + " declaration specifier").c_str());
			$$->is_error = 1;
		}
	}

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

		$$->is_error = $1->is_error || $2->is_error;
	}
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';' 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("struct_declaration", v);

		type = "";
		$$->is_error = $1->is_error || $2->is_error;
	}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("specifier_qualifier_list", v);

		$$->is_error = $1->is_error || $2->is_error; 
		$$->type = $1->type + $2->type;
	}
	| type_specifier	{ $$ = $1; }
	| type_qualifier specifier_qualifier_list 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("specifier_qualifier_list", v);

		$$->is_error = $1->is_error || $2->is_error; 
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

		$$->is_error = $1->is_error || $3->is_error; 
	}
	;

struct_declarator
	: declarator	{ 
		$$ = $1;
		// Semantics
		if (insertStructAttr($1->temp_name, $1->type, $1->size, 0) != 1){
			yyerror(("The Attribute " + string($1->temp_name) + " is already declared in the same struct").c_str());
			$$->is_error = 1;
		} 
	}
	| ':' constant_expression	{ 
		$$ = $2; 
		// yyerror("Didn't implement this yet");
	}
	| declarator ':' constant_expression	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode(":", v);

		// Semantics
		if(!$1->is_error && !$3->is_error){
			if (insertStructAttr($1->temp_name, $1->type, $3->intVal, 0) != 1){
				yyerror(("The Attribute " + string($1->temp_name) + " is already declared in the same struct").c_str());
				$$->is_error = 1;
			}
		}
		else $$->is_error = 1;
	}
	;

enum_specifier
	: ENUM '{' enumerator_list '}'	{
		// TODO
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

		//Semantics
		if(type == "#INSIDE"){
			$$->type = structName + $1->type;
			$$->temp_name = $2->temp_name;
			$$->size = 4;	// BONJOUR
			$$->expType = 2;
		}
		else{
			$$->type = $2->type + $1->type;
			$$->temp_name = $2->temp_name;
			$$->size = 4;	// BONJOUR
			$$->expType = 2;
		}

		//3AC
    	$$->place = qid($$->temp_name, NULL);
		
	}
	| direct_declarator {
		$$ = $1 ;

		// 3AC
		$$->place = qid($$->temp_name, NULL);
	}
	;

direct_declarator
	: IDENTIFIER {
		$$ = makeleaf($1);

		// Semantics
		$$->expType = 1; // Variable
		if(type != "") $$->type = type;
		else $$->type = "int";
		$$->temp_name = string($1);
		$$->size = getSize(type);

		//3AC
		$$->place = qid($$->temp_name, NULL);

	}
	| '(' declarator ')'  {
		$$ = $2 ;

		if($2->expType == 1){

		//3AC
		$$->place = qid($$->temp_name, NULL);
		
		}
	}
	| direct_declarator '[' constant_expression ']'{
		vector<data> v, v2;
		insertAttr(v2, $3, "", 1);
		treeNode* node = makenode("[ ]", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_declarator", v);

		// Semantics
		if(!$1->is_error && !$3->is_error){
			if($1->expType == 1 || $1->expType == 2) {
				$$->expType = 2;
				$$->type = $1->type + "*";
				$$->temp_name = $1->temp_name;
				$$->size = $1->size * $3->intVal;

				//3AC
				$$->place = qid($$->temp_name, NULL);
			}
			else {
				yyerror(( $1->temp_name + " declared as function returning an array").c_str());
				$$->is_error = 1;
			}
		}
		else $$->is_error = 1;
	}
	| direct_declarator '[' ']'{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, NULL, "[ ]", 0);
		$$ = makenode("direct_declarator", v);

		// Semantics
		if(!$1->is_error){
			if($1->expType <=2 ) {
				$$->expType = 2;
				$$->type = $1->type + "*";
				$$->temp_name = $1->temp_name;
				$$->size = 4;	// BONJOUR
				$$->intVal = 8;

				//3AC
				$$->place = qid($$->temp_name, NULL);
			}
			else {
				yyerror(( $1->temp_name + " declared as function returning an array").c_str());
				$$->is_error = 1;
			}
		}
		else $$->is_error = 1;
	}
	| direct_declarator '(' A parameter_type_list ')' NEXT_QUAD {
		vector<data> v, v2;
		insertAttr(v2, $4, "", 1);
		treeNode* node = makenode("( )", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_declarator", v);

		// Semantics
		if(!$1->is_error && !$4->is_error){
			if($1->expType == 1) {
				$$->temp_name = $1->temp_name;
				$$->expType = 3;
				$$->type = $1->type;
				$$->size = getSize($$->type);

				vector<string> temp = getFuncArgs($1->temp_name);
				if(temp.size() == 1 && temp[0] == "#NO_FUNC"){
					insertFuncArg($$->temp_name, funcArgs);
					funcArgs.clear();
					funcName = string($1->temp_name);
					funcType = $1->type;
					//3AC
					$$->place = qid($$->temp_name, NULL);
					backpatch($4->nextlist,$6);
					emit(pair<string,sym_entry*>("FUNC_" + $$->temp_name + " start :",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),-2);
					
				}
				else{
					// Check if temp is correct
					if(temp == funcArgs){
						funcArgs.clear();
						funcName = string($1->temp_name);
						funcType = $1->type;
						//3AC
						$$->place = qid($$->temp_name, NULL);
						backpatch($4->nextlist,$6);
						emit(pair<string,sym_entry*>("FUNC_" + $$->temp_name + " start :",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),-2);
						
					}
					else {
						yyerror(("Conflicting types for function " + $1->temp_name).c_str());
						$$->is_error = 1;
					}
				}

				
			}
			else {
				if($1->expType == 2){
					yyerror( ($1->temp_name + "declared as array of function").c_str());
				}
				else{
					yyerror( ($1->temp_name + "declared as function of function").c_str());
				}
				$$->is_error = 1;
			}
		}
		else $$->is_error =1;
	}
	| direct_declarator '(' A identifier_list ')'{
		// Function should be already declared and used here.

		vector<data> v, v2;
		insertAttr(v2, $4, "", 1);
		treeNode* node = makenode("( )", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_declarator", v);

		// Semantics
		// ToDo : check if A is needed
		// ToDo : Check if func declaration exists and args match
		if(!$1->is_error && !$4->is_error){
			fn_decl = 1;
			$$->temp_name = $1->temp_name;
			$$->expType = 3;
			$$->type = $1->type;
			$$->size = getSize($$->type);
			funcType = $1->type;
			funcName = string($1->temp_name);

			vector<string> args = getFuncArgs($$->temp_name);
			if(args.size() == 1 && args[0] == "#NO_FUNC"){
				args.clear();
				for(int i = 0; i < idList.size(); i++){
					insertSymbol(*curr_table, idList[i], "int", 4, 1, NULL);
					args.push_back("int");
				}
				insertFuncArg($1->temp_name, args);
			}

			if(args.size() == idList.size()) {
				for(int i = 0; i < args.size(); i++) {
					if(args[i] == "..."){
						yyerror(("Conflicting types for function " + $1->temp_name).c_str());
						$$->is_error = 1;
						break;
					}
					insertSymbol(*curr_table, idList[i], args[i], getSize(args[i]), 1, NULL);
				}
				idList.clear();

				
				//3AC
				$$->place = qid($$->temp_name, NULL);
				emit(pair<string,sym_entry*>("FUNC_" + $$->temp_name + " start :",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),-2);

			}
			else {
				yyerror(("Conflicting types for function " + $1->temp_name).c_str());
				$$->is_error = 1;
				idList.clear();
			}
		}
		else $$->is_error = 1;
	}
	| direct_declarator '(' A ')'{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, NULL, "( )", 0);
		$$ = makenode("direct_declarator", v);

		// Semantics
		if(!$1->is_error){
			if($1->expType == 1) {
				$$->temp_name = $1->temp_name;
				$$->expType = 3;
				$$->type = $1->type;
				$$->size = getSize($$->type);

				vector<string> temp = getFuncArgs($1->temp_name);
				if((temp.size() == 1 && temp[0] == "#NO_FUNC") || funcArgs == temp){
					insertFuncArg($$->temp_name, funcArgs);
					funcArgs.clear();
					funcName = string($1->temp_name);
					funcType = $1->type;
				}
				else {
					yyerror(("Conflicting types for function " + $1->temp_name).c_str());
					$$->is_error = 1;
				}

				//3AC
				$$->place = qid($$->temp_name, NULL);
				emit(pair<string,sym_entry*>("FUNC_" + $$->temp_name + " start :",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),pair<string,sym_entry*>("",NULL),-2);
				
			}
			else {
				if($1->expType == 2){
					yyerror( ($1->temp_name + "declared as array of function").c_str());
				}
				else{
					yyerror( ($1->temp_name + "declared as function of function").c_str());
				}
				$$->is_error = 1;
			}
		}
		else $$->is_error = 1;
	}
	;

A
	: %empty	{
		type ="";
		func_flag = 0;
		funcArgs.clear();
		createParamList();
	}

pointer
	: '*' {
		$$ = makeleaf("*(Pointer)");
		$$->type = "*";
	}
	| '*' type_qualifier_list{
		vector<data> v;
		insertAttr(v,$2,"",1);
		$$ = makenode("*(Pointer)",v);
		if($2->is_error)$$->is_error = 1;
		$$->type = "*";
	}
	| '*' pointer{
		vector<data> v;
		insertAttr(v,$2,"",1);
		$$ = makenode("*(Pointer)",v);

		$$->type = "*" + $2->type;
		if($2->is_error)$$->is_error = 1;
	}
	| '*' type_qualifier_list pointer{
		vector<data> v;
		insertAttr(v,$2,"",1);
		insertAttr(v,$3,"",1);
		$$ = makenode("*(Pointer)",v);

		$$->type = "*" + $3->type;
		if($2->is_error || $3->is_error)$$->is_error = 1;
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

		if($1->is_error || $2->is_error)$$->is_error = 1;
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

		// Semantics
		if(!$1->is_error ){
			funcArgs.push_back("...");

			//3AC
			$$->nextlist = $1->nextlist;
		}
		else $$->is_error = 1;
	}
	;


parameter_list
	: parameter_declaration{
		$$ = $1;
	}
	| parameter_list ',' NEXT_QUAD parameter_declaration{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("parameter_list",v);
		if(!$1->is_error && !$4->is_error){
			// 3AC
			backpatch($1->nextlist, $3);
			$$->nextlist = $4->nextlist;
		}
		else $$->is_error = 1;
	}
	;

parameter_declaration
	: declaration_specifiers declarator{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("parameter_declaration",v);

		// Semantics
		if(!$1->is_error && !$2->is_error){
			type = "";
			if($2->expType == 1 || $2->expType == 2) {
				if(currLookup($2->temp_name)) {
					yyerror(("Redeclaration of Parameter " + $2->temp_name).c_str());
					$$->is_error = 1;
				}
				else {
					paramInsert(*curr_table, $2->temp_name, $2->type, $2->size, true, NULL);
				}
				funcArgs.push_back($2->type);
			}
		}
		else $$->is_error = 1;
	}
	| declaration_specifiers abstract_declarator{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("parameter_declaration",v);

		type = "";
		if($1->is_error || $2->is_error)$$->is_error = 1;
	}
	| declaration_specifiers {
		$$ = $1;
		funcArgs.push_back(type);
		type = "";
	}
	;

identifier_list
	: IDENTIFIER {			// Give id types acc to func args
		$$ =makeleaf($1);

		// Semantics
		idList.push_back($1);
	}
	| identifier_list ',' IDENTIFIER {
		vector<data> v;
		insertAttr(v,$1,"",1);
		insertAttr(v,makeleaf($3),"",1);
		$$ = makenode("identifier_list",v);

		// Semantics
		if(!$1->is_error){
			idList.push_back($3);
		}
		else $$->is_error = 1;
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

		$$->type = $1->type + $2->type;
		if($1->is_error || $2->is_error)$$->is_error = 1;
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

		if($1->is_error || $2->is_error)$$->is_error = 1;
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
		if($1->is_error)$$->is_error = 1;
	}
	| direct_abstract_declarator '[' constant_expression ']'{
		vector<data> v, v2;
		insertAttr(v2, $3, NULL, 1);
		treeNode* node = makenode("[ ]", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_abstract_declarator", v);
		if($1->is_error || $3->is_error)$$->is_error = 1;
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
		if($1->is_error)$$->is_error = 1;
	}
	| direct_abstract_declarator '(' parameter_type_list ')'{
		vector<data> v, v2;
		insertAttr(v2, $3, "", 1);
		treeNode* node = makenode("( )", v2);
		insertAttr(v, $1, "", 1);
		insertAttr(v, node, "", 1);
		$$ = makenode("direct_abstract_declarator", v);
		if($1->is_error || $3->is_error)$$->is_error = 1;
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
		if(!$2->is_error){
			//3AC
			$$->place = $2->place;
			$$->nextlist = $2->nextlist;
		}
	}
	;


initializer_list
	: initializer	{
		$$ = $1;
	}
	| initializer_list ',' NEXT_QUAD initializer	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("initializer_list", v);

		if(!$1->is_error && !$4->is_error){
			//3AC
			backpatch($1->nextlist, $3);
			$$->nextlist = $4->nextlist;
		}
		else $$->is_error = 1;
	}
	;


statement
	: labeled_statement		{$$ = $1; type = "";}
	| compound_statement	{$$ = $1; type = "";}
	| expression_statement	{$$ = $1; type = "";}
	| selection_statement	{$$ = $1; type = "";}
	| iteration_statement	{$$ = $1; type = "";}
	| jump_statement		{$$ = $1; type = "";}
	| error ';' 			{$$ = new treeNode; 
				yyclearin; 
				yyerrok; 
				if_found = 0; 
				type = ""; 
				structName = "";
				funcArgs.clear();
				currArgs.pop_back();
	}
	;

labeled_statement
	: IDENTIFIER ':' NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, makeleaf($1), "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("labeled_statement", v);

		if($4->is_error)	{
			$$->is_error = 1;
		}

		if(gotolabel.find($1) != gotolabel.end()){
			yyerror(("duplicate label \'" + string($1) + "\'").c_str());
			$$->is_error = 1;
		}
		else{
			gotolabel.insert({string($1), $3});
		}

		// ??? check if already labelled using same label (else throw error)
		$$->nextlist = $4->nextlist;
		$$->caselist = $4->caselist;
		$$->continuelist = $4->continuelist;
		$$->breaklist = $4->breaklist;
	}
	| CASE_CODE NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("case", v);
	
		if($1->is_error || $3->is_error)	{
			$$->is_error = 1;
		}

		backpatch($1->truelist, $2);
		$3->nextlist.insert($3->nextlist.end(), $1->falselist.begin(), $1->falselist.end());
		$$->breaklist = $3->breaklist;
		$$->nextlist = $3->nextlist;
		$$->caselist = $1->caselist;
		$$->continuelist = $3->continuelist;
	}
	| DEFAULT ':' statement	{
		vector<data> v;
		insertAttr(v, NULL, "default", 0);
		insertAttr(v, $3, "", 1);
		$$ = makenode("case", v);

		if($3->is_error)	{
			$$->is_error = 1;
		}
		
		$$->breaklist= $3->breaklist;
		$$->nextlist = $3->nextlist;
		$$->continuelist=$3->continuelist;
	}
	;

CASE_CODE
	: CASE constant_expression ':' {
        $$ = $2;
		qid t = newtemp($$->type);
		int a = code.size();
		emit(pair <string, sym_entry*>("==", lookup("==")), pair <string, sym_entry*>("", NULL), $2->place, t, -1);
		int b = code.size();
		emit(pair <string, sym_entry*>("GOTO", lookup("goto")), pair <string, sym_entry*>("IF", lookup("if")), t, pair <string, sym_entry*>("", NULL), 0);
		int c = code.size();
		emit(pair <string, sym_entry*>("GOTO", lookup("goto")), pair <string, sym_entry*>("", NULL), pair <string, sym_entry*>("", NULL), pair <string, sym_entry*>("", NULL), 0);
		$$->caselist.push_back(a);
		$$->truelist.push_back(b);
		$$->falselist.push_back(c);
	}
	;

NEXT_QUAD
	: %empty {
		$$ = code.size();
	}
	;

compound_statement
	: '{' '}'	{$$ = makeleaf("{ }");}
	| '{' CHANGE_TABLE statement_list '}'	{
		$$ = $3;

		if(func_flag>=2){
			int bc = block_stack.top();
			block_stack.pop();
			string str = "Block" + to_string(bc);
			string name = funcName+str+".csv";
			printSymbolTable(curr_table, name);
			updSymbolTable(str,0);
			func_flag--;
		}
	}
	| '{' CHANGE_TABLE declaration_list '}'	{
		$$ = $3;

		if(func_flag>=2){
			int bc = block_stack.top();
			block_stack.pop();
			string str = "Block" + to_string(bc);
			string name = funcName+str+".csv";
			printSymbolTable(curr_table, name);
			updSymbolTable(str,0);
			func_flag--;
		}
	}
	| '{' CHANGE_TABLE declaration_list NEXT_QUAD statement_list '}'	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("compound_statement", v);

		if($3->is_error || $5->is_error) {
			$$->is_error = 1;
		}
		
		if(func_flag>=2){
			int bc = block_stack.top();
			block_stack.pop();
			string str = "Block" + to_string(bc);
			string name = funcName+str+".csv";
			printSymbolTable(curr_table, name);
			updSymbolTable(str,0);
			func_flag--;
		}

		backpatch($3->nextlist, $4);
        $$->nextlist = $5->nextlist;
        $$->caselist = $5->caselist;
        $$->continuelist = $5->continuelist;
        $$->breaklist = $5->breaklist;
	}
	;

CHANGE_TABLE
	: %empty {
		if(func_flag){
			string str = "Block" +to_string(block_count);
			block_stack.push(block_count);
			block_count++;
			func_flag++;
			makeSymbolTable(str, "",0);
		}
		else func_flag++;
	}
	;

declaration_list
	: declaration	{$$ = $1;}
	| declaration_list NEXT_QUAD declaration	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("declaration_list", v);

		if($1->is_error || $3->is_error)	{
			$$->is_error = 1;
		}

        backpatch($1->nextlist, $2);
        $$->nextlist = $3->nextlist;
	}	
	;

statement_list
	: statement	{$$ = $1;}
	| statement_list NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("statement_list", v);

		if($1->is_error || $3->is_error)	{
			$$->is_error = 1;
		}

        backpatch($1->nextlist, $2);
        $$->nextlist = $3->nextlist;
		$1->caselist.insert($1->caselist.end(), $3->caselist.begin(), $3->caselist.end());
        $$->caselist = $1->caselist;
		$1->continuelist.insert($1->continuelist.end(), $3->continuelist.begin(), $3->continuelist.end());
		$1->breaklist.insert($1->breaklist.end(), $3->breaklist.begin(), $3->breaklist.end());
        $$->continuelist = $1->continuelist;
        $$->breaklist = $1->breaklist;
	}
	;

expression_statement
	: ';'	{$$ = makeleaf(";");}
	| expression ';'	{$$ = $1;}
	;

IF_CODE
    : IF {if_found = 1;} '(' expression ')' {
        if($4->truelist.empty() && $4->falselist.empty()) {
            int a = code.size();
            emit(qid("GOTO", lookup("goto")),qid("IF", lookup("if")), $4->place, qid("", NULL ),0);
            int b = code.size();
            emit(qid("GOTO", lookup("goto")),qid("", NULL), qid("", NULL), qid("", NULL ),0);
            $4->truelist.push_back(a);
            $4->falselist.push_back(b);
        }
        $$ = $4;
		if_found = 0;
    }
	;

N
    : %empty {
        int a = code.size();
		$$ = new treeNode;
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
        $$->nextlist.push_back(a);
    }
    ;

selection_statement
	: IF_CODE NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("if", v);

		if($1->is_error || $3->is_error)	{
			$$->is_error = 1;
		}

        backpatch($1->truelist, $2);
		$3->nextlist.insert($3->nextlist.end(), $1->falselist.begin(), $1->falselist.end());
        $$->nextlist= $3->nextlist;
        $$->continuelist = $3->continuelist;
        $$->breaklist = $3->breaklist;
	}
	| IF_CODE NEXT_QUAD statement N ELSE NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		insertAttr(v, $7, "", 1);
		$$ = makenode("if-else", v);

		if($1->is_error || $3->is_error || $7->is_error)	{
			$$->is_error = 1;
		}

        backpatch($1->truelist, $2);
        backpatch($1->falselist, $6);
		$3->nextlist.insert($3->nextlist.end(), $4->nextlist.begin(), $4->nextlist.end());
		$3->nextlist.insert($3->nextlist.end(), $7->nextlist.begin(), $7->nextlist.end());
        $$->nextlist = $3->nextlist;
		$3->breaklist.insert($3->breaklist.end(), $7->breaklist.begin(), $7->breaklist.end());
		$$->breaklist = $3->breaklist;
		$3->continuelist.insert($3->continuelist.end(), $7->continuelist.begin(), $7->continuelist.end());
		$$->continuelist = $3->continuelist;
	}
	| SWITCH '(' expression ')' statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("switch", v);

		if($3->is_error || $5->is_error)	{
			$$->is_error = 1;
		}

        casepatch($5->caselist, $3->place);
        $5->nextlist.insert($5->nextlist.end(), $5->breaklist.begin(), $5->breaklist.end());
		$$->nextlist= $5->nextlist;
        $$->continuelist= $5->continuelist;
	}
	;

EXPR_CODE
    : {if_found = 1;} expression {
        if($2->truelist.empty() && $2->falselist.empty()) {
            int a = code.size();
            emit(qid("GOTO", lookup("goto")),qid("IF", lookup("if")), $2->place, qid("", NULL ),0);
            int b = code.size();
            emit(qid("GOTO", lookup("goto")),qid("", NULL), qid("", NULL), qid("", NULL ),0);
            $2->truelist.push_back(a);
            $2->falselist.push_back(b);
        }
        $$ = $2;
		if_found = 0;
    }
    ;

EXPR_STMT_CODE
    : {if_found = 1;} expression_statement { 
		if($2->truelist.empty() && $2->falselist.empty()) {
            int a = code.size();
            emit(qid("GOTO", lookup("goto")),qid("IF", lookup("if")), $2->place, qid("", NULL ),0);
            int b = code.size();
            emit(qid("GOTO", lookup("goto")),qid("", NULL), qid("", NULL), qid("", NULL ),0);
            $2->truelist.push_back(a);
            $2->falselist.push_back(b);
        }
        $$ = $2;
		if_found = 0;
	}
    ;

iteration_statement
	: WHILE '(' NEXT_QUAD EXPR_CODE ')' NEXT_QUAD statement {
		vector<data> v;
		insertAttr(v, $4, "", 1);
		insertAttr(v, $7, "", 1);
		$$ = makenode("while-loop", v);

		if($4->is_error || $7->is_error)	{
			$$->is_error = 1;
		}
	
        backpatch($4->truelist, $6);
		$7->nextlist.insert($7->nextlist.end(), $7->continuelist.begin(), $7->continuelist.end());
        backpatch($7->nextlist, $3);
        $$->nextlist = $4->falselist;
        $$->nextlist.insert($$->nextlist.end(), $7->breaklist.begin(), $7->breaklist.end());
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), $3);
    }
	| DO NEXT_QUAD statement WHILE '(' NEXT_QUAD EXPR_CODE ')' ';'	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $7, "", 1);
		$$ = makenode("do-while-loop", v);

		if($3->is_error || $7->is_error)	{
			$$->is_error = 1;
		}

        backpatch($7->truelist, $2);
        $3->nextlist.insert($3->nextlist.end(), $3->continuelist.begin(), $3->continuelist.end());
		backpatch($3->nextlist, $6);
        $$->nextlist = $7->falselist;
		$$->nextlist.insert($$->nextlist.end(), $3->breaklist.begin(), $3->breaklist.end());
	}
	| FOR '(' expression_statement NEXT_QUAD EXPR_STMT_CODE ')' NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		insertAttr(v, $8, "", 1);
		$$ = makenode("for-loop(w/o update stmt)", v);

		if($3->is_error || $5->is_error || $8->is_error)	{
			$$->is_error = 1;
		}

        backpatch($3->nextlist, $4);
        backpatch($5->truelist, $7);
        $$->nextlist = $5->falselist;
		$$->nextlist.insert($$->nextlist.end(), $8->breaklist.begin(), $8->breaklist.end());
        $8->nextlist.insert($8->nextlist.end(), $8->continuelist.begin(), $8->continuelist.end());
        backpatch($8->nextlist, $4);
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), $4);
    }
	| FOR '(' expression_statement NEXT_QUAD EXPR_STMT_CODE NEXT_QUAD expression N ')' NEXT_QUAD statement	{
		vector<data> v;
		insertAttr(v, $3, "", 1);
		insertAttr(v, $5, "", 1);
		insertAttr(v, $7, "", 1);
		insertAttr(v, $11, "", 1);
		$$ = makenode("for-loop", v);

		if($3->is_error || $5->is_error || $7->is_error || $11->is_error)	{
			$$->is_error = 1;
		}
	
        backpatch($3->nextlist, $4);
        backpatch($5->truelist, $10);
        $$->nextlist = $5->falselist;
		$$->nextlist.insert($$->nextlist.end(), $11->breaklist.begin(), $11->breaklist.end());
		$11->nextlist.insert($11->nextlist.end(), $11->continuelist.begin(), $11->continuelist.end());
        backpatch($11->nextlist, $6);
		$7->nextlist.insert($7->nextlist.end(), $8->nextlist.begin(), $8->nextlist.end());
        backpatch($7->nextlist, $4);
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), $6);
    }
	;

		 
jump_statement
	: GOTO IDENTIFIER ';'	{
		string s;
		s = (string)$1 + " : " + (string)$2;
        $$ = makeleaf(s);

        int a = code.size();
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
        // store a somewhere and backpatch a with the goto address later (idk how) and error handling
        gotolablelist[$2].push_back(a);
    }
	| CONTINUE ';'	{
        $$ = makeleaf($1);
        
        int a = code.size();
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
        $$->continuelist.push_back(a);
    }
	| BREAK ';'		{
        $$ = makeleaf($1);
        
        int a = code.size();
        emit(qid("GOTO", lookup("goto")), qid("", NULL), qid("", NULL), qid("", NULL), 0);
        $$->breaklist.push_back(a);
    }
	| RETURN ';'	{
		$$ = makeleaf($1);

        emit(qid("RETURN", lookup("return")), qid("", NULL), qid("", NULL), qid("", NULL), -1);
	}
	| RETURN expression ';'	{
		vector<data> v;
		insertAttr(v, makeleaf($1), "", 1);
		insertAttr(v, $2, "", 1);
		$$ = makenode("jump_stmt", v);

		if($2->is_error)	{
			$$->is_error = 1;
		}

        emit(qid("RETURN", lookup("return")), $2->place, qid("", NULL), qid("", NULL), -1);
	}
	;

translation_unit 
	: external_declaration	{
		$$ = $1;
	}
	| translation_unit NEXT_QUAD external_declaration	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("program", v);

		if($1->is_error || $3->is_error)	{
			$$->is_error = 1;
			// Do delete stuff
		}

        backpatch($1->nextlist, $2);
        $$->nextlist = $3->nextlist;
		$1->caselist.insert($1->caselist.end(), $3->caselist.begin(), $3->caselist.end());
        $$->caselist = $1->caselist;
		$1->continuelist.insert($1->continuelist.end(), $3->continuelist.begin(), $3->continuelist.end());
        $1->breaklist.insert($1->breaklist.end(), $3->breaklist.begin(), $3->breaklist.end());
        $$->continuelist = $1->continuelist;
        $$->breaklist = $1->breaklist;
	}
	;

external_declaration
	: function_definition	{ $$ = $1; }
	| declaration			{ $$ = $1; }
	;


function_definition
	: declaration_specifiers declarator F declaration_list compound_statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		insertAttr(v, $4, "", 1);
		insertAttr(v, $5, "", 1);
		$$ = makenode("function", v);

		// Semantics
		type = "";
		funcName = "";
		funcType = "";
		if($1->is_error || $2->is_error || $4->is_error || $5->is_error) {
			$$->is_error = 1;
		}

		if($3->is_error) {
			$$->is_error = 1;
			removeFuncProto();
		}
		else {
			
			string fName = $3->node_name;
			printSymbolTable(curr_table ,fName + ".csv");
			updSymbolTable(fName,1);
			emit(qid("FUNC_" + $3->node_name + " end :", NULL), qid("", NULL), qid("", NULL), qid("", NULL), -1);
			backpatch_rem();
		}
	}

	| declaration_specifiers declarator F compound_statement 	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $2, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("function (w/o decl_list)", v);

		// Semantics
		type = "";
		funcName = "";
		funcType = "";
		if($1->is_error || $2->is_error || $4->is_error) {
			$$->is_error = 1;
		}

		if($3->is_error) {
			$$->is_error = 1;
			removeFuncProto();
		}
		else {
			
			string fName = $3->node_name;
			printSymbolTable(curr_table ,fName + ".csv");
			updSymbolTable(fName,1);
			emit(qid("FUNC_" + $3->node_name + " end :", NULL), qid("", NULL), qid("", NULL), qid("", NULL), -1);
			backpatch_rem();
		}

        // 3AC not done
	}
	| declarator F declaration_list compound_statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		insertAttr(v, $4, "", 1);
		$$ = makenode("function (w/o decl_specifiers)", v);

		// Semantics
		type = "";
		funcName = "";
		funcType = "";
		if($1->is_error || $3->is_error || $4->is_error) {
			$$->is_error = 1;
		}

		if($2->is_error) {
			$$->is_error = 1;
			removeFuncProto();
		}
		else {
			
			string fName = $2->node_name;
			printSymbolTable(curr_table ,fName + ".csv");
			updSymbolTable(fName,1);
			emit(qid("FUNC_" + $3->node_name + " end :", NULL), qid("", NULL), qid("", NULL), qid("", NULL), -1);
			backpatch_rem();
		}

        // 3AC not done
	}
	| declarator F compound_statement	{
		vector<data> v;
		insertAttr(v, $1, "", 1);
		insertAttr(v, $3, "", 1);
		$$ = makenode("function (w/o specifiers and decl_list)", v);

		// Semantics
		type = "";
		funcName = ""; 
		funcType = "";
		if($1->is_error || $3->is_error) {
			$$->is_error = 1;
		}

		if($2->is_error) {
			$$->is_error = 1;
			removeFuncProto();
		}
		else {
			string fName = $2->node_name;
			printSymbolTable(curr_table ,fName + ".csv");
			updSymbolTable(fName,1);
			emit(qid("FUNC_" + $3->node_name + " end :", NULL), qid("", NULL), qid("", NULL), qid("", NULL), -1);
			backpatch_rem();
		}

        // 3AC not done
	}
	;


F 
	: %empty 		{
		$$ = new treeNode;
		clear_paramoffset();
		if (gst.find(funcName) != gst.end()){
			yyerror(("Redefinition of function " + funcName).c_str());
			$$->is_error = 1;
		}
		else{
			makeSymbolTable(funcName, funcType,1);
			$$->node_name = (funcName);
			block_count = 1;
			type = "";
		}
	}

%%

void print_error(){
	cout<<"\033[1;31mError: \033[0m";
}

void print_warning(){
	cout<<"\033[1;36mWarning: \033[0m";
}

void print_options(){
	// To be constructed later
	cout<<"Usage: parser [OPTIONS] file...\n\n";
	cout<<"Options:\n";
	cout<<"\t--help\t\t\tDisplay available options\n";
	cout<<"\t-l <file>\t\tonly runs the lexer and dumps output in <file>\n";
	cout<<"\t-o <file>\t\tdump the dot script generated in <file>\n";
	cout<<"\n\n";
}

void no_file_present(){
	print_error();
	cout<<"no input files\nCompilation terminated\n";
}


int yyerror(const char* s) { 
	
	FILE *dupfile = fopen(curr_file, "r");
	int count = 1;
	char currline[256]; /* or other suitable maximum line size */
	while (fgets(currline, sizeof(currline), dupfile) != NULL) {
		if (count == line){
			cout<<curr_file<<":"<<line<<":"<<column+1-strlen(yytext)<<":: "<<currline;
			print_error();
			cout<<s<<"\n\n";
			// exit(0);
			return -1;
		}
		else{
			count++;
		}
	}
	print_error();
	cout<<s<<endl;
	fclose(dupfile);
	return -1;
}

int warning(const char* s) { 
	FILE *dupfile = fopen(curr_file, "r");
	int count = 1;

	char currline[256]; /* or other suitable maximum line size */
	while (fgets(currline, sizeof(currline), dupfile) != NULL) {
		if (count == line){
			cout<<curr_file<<":"<<line<<":"<<column+1-strlen(yytext)<<":: "<<currline;
			print_warning();
			cout<<s<<"\n\n";
			return -1;
		}
		else{
			count++;
		}
	}

	fclose(dupfile);
	return 1;
}

int main(int argc, char* argv[]){
	
	char* file_name = "graph.dot", *lexer_file_name;
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
				print_error();
				cout<<"missing filename after \'-o\'\nCompilation terminated\n";
				return -1;
			}
			else{
				file_name = argv[i+1];
				i++;
			}
		}
		else if(!strcmp(argv[i], "-l")){
			if(i+1 >= argc || argv[i+1][0] == '-'){
				print_error();
				cout<<"missing filename after \'-l\'\nCompilation terminated\n";
				return -1;
			}
			else{
				only_lexer = 1;
				lexer_file_name = argv[i+1];
				i++;
			}
		}
		else if(argv[i][0] != '-') file_present++;
	}

	if(!file_present){
		no_file_present();
		return -1;
	}

	if( only_lexer ){
		lexer_file = fopen(lexer_file_name, "w");

		if(lexer_file == NULL){
			print_error();
			cout<<"cannot open file "<<lexer_file_name<<"\nCompilation terminated\n";
			return -1;
		}

		for(int i = 1; i<argc; i++){
			if(!strcmp(argv[i], "-o") || !strcmp(argv[i], "-l")){
				i++;
				continue;
			}

			yyin = fopen(argv[i], "r");
			
			// File open failed, proceeding to next file(s), if exist
			if(yyin == NULL){
				print_error();
				cout<<"cannot open file "<<argv[i]<<"\n\n";
				continue;
			}
			line = 1, column = 0;
			yyrestart(yyin);
			
			fprintf(lexer_file, "----------Lexer Output for file %s----------\n", argv[i]);
			fprintf(lexer_file, "TOKEN\t\t\tLEXEME\t\t\tLINE#\tCOLUMN#\n");
			while( yylex() > 0 ){

			}
			fprintf(lexer_file, "------------------------END of Output---------------------\n\n");
		}

		return 0;

	}

	dotfile = fopen(file_name, "w");
	
	if(dotfile == NULL){
		print_error();
		cout<<"cannot open the dot file "<<file_name<<"\nCompilation terminated\n";
		return -1;
	}
	symTable_init();
	beginAST();
	
	for(int i = 1; i<argc; i++){
		if(!strcmp(argv[i], "-o")){
			i++;
			continue;
		}

		yyin = fopen(argv[i], "r");
		
		// File open failed, proceeding to next file(s), if exist
		if(yyin == NULL){
			print_error();
			cout<<"cannot open file "<<argv[i]<<"\n\n";
			continue;
		}

		line = 1, column = 0;
		curr_file = argv[i];
		
		yyrestart(yyin);
		yyparse();
		code_file.open("gen_code.asm");
		
		
		// if(last[0] != ';' && last[0] != '}' ){
		// 	print_error();
		// 	cout<<" syntax error, expected ';' or '}' at end of file\n";  
		// }
		
	}

	for(auto i: gotolablelist){
		if(gotolabel.find(i.first) == gotolabel.end()){
			yyerror(("label \'" + string(i.first) + "\' used but not defined").c_str());
		}
		else backpatch(i.second, gotolabel[i.first]);
	}

	print3AC_code();
	genCode();
	endAST();

	printSymbolTable(&gst, "#Global_Symbol_Table#.csv");
	return 0;
}





