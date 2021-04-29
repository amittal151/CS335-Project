#include "codegen.h"

map<string, set<qid> > reg_desc;
set<long long> leaders; 
qid empty_var("", NULL);

extern vector<quad> code;
extern ofstream code_file;

void gen_data_section(){
    code_file << "extern printf\n";
}

void starting_code(){
    code_file << "\nsection .text\n";
    code_file << "\tglobal main\n";
}

int is_integer(string sym){
    for(int i=0; i<sym.length(); i++){
        if(sym[i] >= '0' && sym[i]<='9'){
            continue;
        }
        else return 0;
    }
    return 1;
}
// x = 1
void add_op(quad* instr){
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    string mem2 = get_mem_location(&instr->arg2);
    code_file << "\tadd " << reg1 << ", " << mem2 <<endl;
    update_reg_desc(reg1, &instr->res);
}

void assign_op(quad* instr){
    // x = 1
    if(is_integer(instr->arg1.first)){
        // string reg = getReg(instr->res, qid("", NULL), qid("", NULL), instr->idx);
        string mem = get_mem_location(&instr->res);
        code_file << "\tmov "<< mem << ", dword "<< stoi(instr->arg1.first) <<endl;
    }
    // x = y
    else{
        string reg = getReg(&instr->arg1, &instr->res, &empty_var, instr->idx);
        update_reg_desc(reg, &instr->res);        // since reg will still hold y's value, keep y in reg
        reg_desc[reg].insert(instr->arg1);
        instr->arg1.second->addr_descriptor.reg = reg;
    }
}

void gen_func_label(quad* instr){
    if(instr->op.first.substr(0, 5) == "FUNC_" && instr->op.first[(instr->op.first.size() - 3)] == 't'){
        string s = "";
        for(int i=5;i<instr->op.first.size(); i++){
            if(instr->op.first[i] == ' ')break;
            s += instr->op.first[i];
        }
        code_file << s << " :\n";
        code_file << "\tpush rbp\n";
        code_file << "\tmov rbp, rsp\n"; 
        code_file << "\tsub rsp, 16\n";  // TODO
    }
}


void genCode(){
    // Prints final code to be generated in asm file
    findBasicBlocks();
    initializeRegs();
    nextUse();
    
    gen_data_section();
    starting_code();


    for (auto it=leaders.begin(); it != leaders.end(); it++){
        auto it1 = it;
        it1++;
        if(it1 == leaders.end()) break;
        int ended = 0;
        ull start = *it;
        ull end = *it1;
        
        for(int idx=start; idx < end; idx++){
            quad instr = code[idx];
            if(instr.op.first.substr(0, 5) == "FUNC_" && instr.op.first[(instr.op.first.size() - 3)] == 't'){
                gen_func_label(&instr);
            }
            if(instr.op.first[0] == '+')    add_op(&instr);
            if(instr.op.first == "=")   assign_op(&instr);
            if(instr.op.first == "CALL" );
            if(instr.op.first.substr(0, 5) == "FUNC_" && instr.op.first[(instr.op.first.size() - 3)] == 'd'){
                ended = 1;
                end_basic_block();
                code_file << "\txor rax, rax\n";
                code_file << "\tleave\n";
                code_file << "\tret\n";
            }
        }
        if(!ended) end_basic_block();
    }

}

void end_basic_block(){
    for(auto reg: reg_desc){
        for(auto sym: reg.second){
            if(sym.first[0] == '#') continue;
            sym.second->addr_descriptor.reg = "";
            code_file<<"\tmov " << get_mem_location(&sym) <<", "<<reg.first<<"\n";
        }
        reg.second.clear();
    }
}


void update_reg_desc(string reg, qid* sym){
    for(auto it: reg_desc[reg]){
        it.second->addr_descriptor.reg = "";
    }
    reg_desc[reg].clear();
    reg_desc[reg].insert(*sym);          // x = y + z; 
    sym->second->addr_descriptor.heap = false;
    sym->second->addr_descriptor.stack = false;
    sym->second->addr_descriptor.reg = reg;
}

void initializeRegs(){
    // Add more registers later
    reg_desc.insert(make_pair("rax", set<qid> () ));
    reg_desc.insert(make_pair("rcx", set<qid> () ));
    reg_desc.insert(make_pair("rdx", set<qid> () ));
    reg_desc.insert(make_pair("rbx", set<qid> () ));
    reg_desc.insert(make_pair("rsi", set<qid> () ));
    reg_desc.insert(make_pair("rdi", set<qid> () ));
}


void freeDeadTemp(ull idx){
    // free registers allocated to Dead temporaries
    for(auto it : reg_desc){
        vector<qid> temp;
        for(auto sym : it.second){
            if(sym.second->next_use < idx && sym.second->next_use != -1){
                temp.push_back(sym);
                sym.second->addr_descriptor.reg = "";
            }
        }
        for (auto v : temp){
            it.second.erase(v);
        }
    }
}

string get_mem_location(qid* sym){

    if(sym->second->addr_descriptor.reg != ""){
        return sym->second->addr_descriptor.reg;
    }

    if(sym->second->heap_mem == 0){
        //Symbol in stack
        ull offset = sym->second->offset;
        ull size = sym->second->size;
        sym->second->addr_descriptor.stack = true;
        return string("[ rbp - " + to_string(offset + size) + " ]");
    }
    
    sym->second->addr_descriptor.stack = false;
    sym->second->addr_descriptor.heap = true;
    return string("[ " + to_string(sym->second->heap_mem) + " ]");
}

string getReg(qid* sym, qid* result, qid* sym2, int idx){
    // Allocates best register if available
    freeDeadTemp(idx);

    // Case 1
    string reg = "";
    if(sym->second->addr_descriptor.reg != "") {
        reg = sym->second->addr_descriptor.reg;
        if(sym->first[0] != '#' && !(sym->second->addr_descriptor.stack || sym->second->addr_descriptor.heap)){
            sym->second->addr_descriptor.reg = "";
            code_file << "\tmov " << get_mem_location(sym) << ", " << reg <<endl;
        }
        return reg;
    }

    int mn = 1000000;
    
    
    for (auto it : reg_desc){
        if( (it.second.size() != 0 && (it.second.begin())->first[0] == '#' ) || (it.second.find(*sym2) != it.second.end()) ){
            // skip registers containing temp. variables
            continue;
        }
        if (it.second.size() < mn){
            mn =  it.second.size();
            reg = it.first; 
        }
    } 
    assert(reg != "");

    for (auto r : reg_desc[reg]){
        // Case 3 : 
        qid q = r;
        if(q.second->addr_descriptor.stack || q.second->addr_descriptor.heap){
            q.second->addr_descriptor.reg = "";
        }
        else{
            // Reg Spill and store in memory
            q.second->addr_descriptor.reg = "";
            code_file << "\tmov " << get_mem_location(&q) << ", " << reg <<endl;
        }
        
    }
    reg_desc[reg].clear();

    code_file << "\tmov " << reg << ", "<< get_mem_location(sym) <<endl;
    sym->second->addr_descriptor.reg = reg;
    reg_desc[reg].insert(*sym);
    return reg;
}


void nextUse(){
    for(auto it=leaders.begin(); it != leaders.end(); it++){
        auto it1 = it;
        it1++;
        if(it1 == leaders.end()) break;

        for(int i= (*it1)-1; i>= (*it); i--){
            if(code[i].arg1.first != "" && code[i].arg1.first[0] == '#' && code[i].arg1.second && code[i].arg1.second->next_use == -1){
                code[i].arg1.second->next_use = i;
            } 
            if(code[i].arg2.first != "" && code[i].arg2.first[0] == '#' && code[i].arg2.second && code[i].arg2.second->next_use == -1){
                code[i].arg2.second->next_use = i;
            } 
        }
    }
}

void findBasicBlocks(){
    // Finds Basic block in 3AC code.

    for (long long i=0;i< (long long)code.size(); i++){
        if (i == 0){
            leaders.insert(i);
            continue;
        }
        if(code[i].op.first.substr(0, 5) == "FUNC_"){
                if(code[i].op.first[code[i].op.first.length()-3] == 't')leaders.insert(i);
                else if(i+1 != code.size()) leaders.insert(i+1);
        }
        if(code[i].op.first == "GOTO"){
            leaders.insert(code[i].idx);
            if(!(code[i+1].op.first.substr(0, 5) == "FUNC_" &&  code[i].op.first[code[i].op.first.length()-3] == 'd'))leaders.insert(i+1);
        }   
    }
    leaders.insert(code.size());
}

