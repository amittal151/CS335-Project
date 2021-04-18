#include <fstream>
#include "3ac.h"

using namespace std;

vector<quad> code;

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
























