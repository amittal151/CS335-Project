#include "nodes.h"

extern FILE *dotfile;


long unsigned int NodeCounter = 0;
void beginAST(){
	fprintf(dotfile, "digraph AST {\n\tordering=out;\n");
}
void endAST(){
	fprintf(dotfile, "}\n");
}

vector<data> createVector(){
	vector<data> attr;
	return attr;
}

void insertAttr(vector<data> &v, treeNode* nod, string s, int flag){
	data d;
	d.node = nod;
	d.str = s;
	d.is_node = flag;
	v.push_back(d);
}

treeNode *terminal(string str){
	treeNode *node = new treeNode;
	node->node_id = ++NodeCounter;
	
	string tmp = "";
	for(int i=0; i<str.length(); ++i){
		tmp+=str[i];
		if(str[i]=='\\') tmp+=str[i];
	}
	node->node_name = tmp;

	if(str[0]=='"'){
		string s = tmp.substr(1,tmp.length()-2);
		fprintf(dotfile, "\t%lu [label=\"\\\"%s\\\"\"];\n", node->node_id,node->node_name.c_str());
	}
	else{
		fprintf(dotfile, "\t%lu [label=\"%s\"];\n", node->node_id,node->node_name.c_str() );
	}

	return node;
}

treeNode *nonTerminal(string s, vector<data> &v){
	treeNode *node = new treeNode;
	node->node_name = s;
	node->node_id = ++NodeCounter;

	vector<long unsigned int> op_id;

	for(int i = 0; i<v.size(); ++i){
		if(!v[i].is_node){
			long unsigned int opid = ++NodeCounter;
			op_id.push_back(opid);
			if(v[i].str!="") fprintf(dotfile, "\t%lu [label=\"%s\"];\n", opid, v[i].str.c_str());
		}
	}
	fprintf(dotfile, "\t%lu [label=\"%s\"];\n", node->node_id, node->node_name.c_str());

	int j=0;
	for(int i=0; i<v.size(); ++i){
		if(v[i].is_node && v[i].node) fprintf(dotfile, "\t%lu -> %lu;\n", node->node_id, v[i].node->node_id);
		if(!v[i].is_node){
			if(v[i].str!="") fprintf(dotfile, "\t%lu -> %lu;\n", node->node_id, op_id[j]);
			j++;
		}
	}

	return node;

}
