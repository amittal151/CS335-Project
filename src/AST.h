#include <bits/stdc++.h>
#include "3ac.h"
using namespace std;


typedef struct{
	long unsigned int node_id;
	long long int size;
	string node_name;
	string type;
	int expType;	// 1 -> Variable, 2 -> Array, 3-> Function, 4 -> Constant, 5 -> string  			 	
	int isInit;
	long long int intVal;
	long double realVal;
	string strVal;

	string temp_name;
	qid place;
	vector<int> truelist;
	vector<int> falselist;
	vector<int> breaklist;
	vector<int> continuelist;
	vector<int> nextlist;;
	vector<int> caselist;
}treeNode;


typedef struct{
	string str;
	string type;
	long long int intVal;
	long double realVal;
	string strVal;
}constants;


typedef struct{
	treeNode* node;
	string str;
	bool is_node;
}data;




void beginAST();
void endAST();

vector<data> createVector();
void insertAttr(vector<data>&, treeNode* , string , int );
treeNode *makeleaf(string);
treeNode *makenode(string , vector<data>&);
