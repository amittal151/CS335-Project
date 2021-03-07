#include <bits/stdc++.h>
using namespace std;


typedef struct{
	long unsigned int node_id;
	string node_name;
	long long intVal;
	long long realVal;
	char charVal;
	string strVal;
}treeNode;

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
