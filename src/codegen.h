#pragma once
#include <bits/stdc++.h>
#include "3ac.h"
using namespace std;


void gen_data_section();
void starting_code();
void add_op(quad instr);
void gen_func_label(quad instr);
void genCode();
void update_reg_desc(string reg, qid sym);
void initializeRegs();
void freeDeadTemp(ull idx);
string get_mem_location(qid sym);
string getReg(qid sym, qid result, qid sym2, int idx);
void nextUse();
int is_integer(string sym);
void assign_op(quad instr);
void findBasicBlocks();