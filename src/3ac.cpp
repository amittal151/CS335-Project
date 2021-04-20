#include <fstream>
#include "3ac.h"

using namespace std;

vector<quad> code;
long long counter = 0;

void emit(qid op, qid arg1, qid arg2, qid res, int idx){
    quad temp;
    temp.op = op;
    temp.arg1 = arg1;
    temp.arg2 = arg2;
    temp.res = res;
    temp.idx = idx;
    code.push_back(temp);
}

void backpatch(vector<int>& bplist, int target){
    for(int i=0;i<bplist.size(); i++){
        code[bplist[i]].idx = target;
    }
}

qid newtemp(string type){
    string temp_var = "#V"+to_string(counter);
    counter++;
    insertSymbol(*curr_table, temp_var, type, getSize(type), 0, NULL);
    return qid(temp_var, lookup(temp_var));
}
























