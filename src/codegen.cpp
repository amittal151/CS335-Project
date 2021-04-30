#include "codegen.h"

map<string, set<qid> > reg_desc;
set<long long> leaders; 
vector<qid> params; // stores the parameters as soon as we encounter first param
map<int, string> stringlabels;

int string_counter = 0; 
int label_counter = 0;

qid empty_var("", NULL);

extern vector<quad> code;
extern ofstream code_file;

string get_label(){
    return "L" +to_string(label_counter++);
}

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
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){

    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        string mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\tadd " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void sub_op(quad* instr){
    // x = 2 - 3
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){

    }
    // x = 1 - b
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        string mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\tsub " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void mul_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){

    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        string mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\timul " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void div_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){

    }
    else{
        free_reg("eax");
        free_reg("edx");
        code_file<<"\tmov eax"<<", "<<get_mem_location(&instr->arg1, 0)<<"\n";
        reg_desc["eax"].insert(instr->arg2);
        reg_desc["edx"].insert(instr->arg2);
        string reg2 = getReg(&instr->arg2, &instr->res, &empty_var, instr->idx);
        
        code_file<<"\tcdq\n";
        code_file<<"\tidiv "<<reg2<<"\n";
        instr->res.second->addr_descriptor.reg = "eax";
        reg_desc["eax"].clear();
        reg_desc["edx"].clear();
        reg_desc["eax"].insert(instr->res);
    }
}

void mod_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){

    }
    else{
        free_reg("eax");
        free_reg("edx");
        code_file<<"\tmov eax"<<", "<<get_mem_location(&instr->arg1, 0)<<"\n";
        reg_desc["eax"].insert(instr->arg2);
        reg_desc["edx"].insert(instr->arg2);
        string reg2 = getReg(&instr->arg2, &instr->res, &empty_var, instr->idx);
        
        code_file<<"\tcdq\n";
        code_file<<"\tidiv "<<reg2<<"\n";
        instr->res.second->addr_descriptor.reg = "edx";
        reg_desc["eax"].clear();
        reg_desc["edx"].clear();
        reg_desc["edx"].insert(instr->res);
    }
}

void return_op(quad* instr){
    // return a;
    if(instr->arg1.first != ""){
        clear_regs();
        string mem = get_mem_location(&instr->arg1, 1);
        if(mem != "eax") code_file<<"\tmov eax, "<<mem<<"\n";
        code_file<<"\tleave\n";
        code_file<<"\tret\n";
    }
    else{
        clear_regs();
        code_file<<"\txor eax, eax\n";
        code_file<<"\tleave\n";
        code_file<<"\tret\n";
    }
}

void clear_regs(){
    for(auto reg: reg_desc){
        reg.second.clear();
    }
}


// free a specific register
// eg for div we need eax, edx
void free_reg(string reg){
    for(auto sym: reg_desc[reg]){
        sym.second->addr_descriptor.reg = "";
        code_file<<"\tmov "<<get_mem_location(&sym, 1)<<", "<<reg<<"\n";
    }
    code_file<<"\txor "<<reg<<", "<<reg<<"\n";
}

void call_func(quad *instr){
    vector<string> func_regs = {"edi", "esi", "edx", "ecx", "r8d", "r9d"};
    int curr_reg = 0;
    cout<<params.size()<<"\n";
    for(int i = params.size()-1; i>=0; i--){
        // free_reg(func_regs[curr_reg]);
        // cout<<params[i].first<<"---\n";
        if(params[i].first[0] == '\"'){
            string temp = params[i].first;
            temp[0] = '`', temp[temp.length()-1] = '`';
            stringlabels.insert({string_counter, temp});
            // code_file<<"\tmov "<<func_regs[curr_reg]<<", str"<<string_counter<<"\n";
            code_file<<"\tpush str"<<string_counter<<"\n";
            string_counter++;
        }
        else{
            // code_file<<"\tmov "<<func_regs[curr_reg]<<", "<<get_mem_location(&it, 1)<<"\n";
            string mem = get_mem_location(&params[i], 1);
            if(reg_desc.find(mem) == reg_desc.end()) mem = "dword "+mem;
            code_file<<"\tpush "<<mem<<"\n";
        }
        // curr_reg++;
    }
    
    code_file<<"\tcall "<<instr->arg1.first<<"\n";
    
    // Clear args from stack
    code_file<<"\tadd esp, "<<4*params.size()<<"\n";
    reg_desc["eax"].insert(instr->res);
    instr->res.second->addr_descriptor.reg = "eax";

    params.clear();
}

void assign_op(quad* instr){
    // x = 1
    if(is_integer(instr->arg1.first)){
        // string reg = getReg(instr->res, qid("", NULL), qid("", NULL), instr->idx);
        string mem = get_mem_location(&instr->res, 1);
        code_file << "\tmov "<< mem << ", dword "<< stoi(instr->arg1.first) <<endl;
    }
    // x = y
    else{
        string reg = getReg(&instr->arg1, &instr->res, &empty_var, instr->idx);
        cout<<reg<<" ---\n";
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
        code_file << "\tpush ebp\n";
        code_file << "\tmov ebp, esp\n"; 
        code_file << "\tsub esp, 16\n";  // TODO
    }
}


void lshift_op(quad* instr){    // <<
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    string mem2;
    if(is_integer(instr->arg2.first)) mem2 = instr->arg2.first;
    mem2 = get_mem_location(&instr->arg2, 0);
    code_file << "\tshl " << reg1 << ", " << mem2 <<"\n";
    update_reg_desc(reg1, &instr->res);
}

void rshift_op(quad* instr){    // >>
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    string mem2;
    if(is_integer(instr->arg2.first)) mem2 = instr->arg2.first;
    mem2 = get_mem_location(&instr->arg2, 0);
    code_file << "\tshr " << reg1 << ", " << mem2 <<"\n";
    update_reg_desc(reg1, &instr->res);
}

void logic_and(quad *instr){
	string l1 = "", l2 = "";
    l1 = get_label();
    l2 = get_label();
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);    

	if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
		int a = stoi(instr->arg1.first);
		int b = stoi(instr->arg2.first);
		if(a && b){
			code_file << "\tmov "<<reg<<", dword "<<1<<"\n";
		}
		else{
			code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
		}
	}
	else{
		string mem2 = get_mem_location(&instr->arg2, 0);
	
		code_file << "\tcmp "<<reg<<", "<<0<<"\n";
		code_file << "\tje "<<l1<<"\n";
		code_file << "\tcmp "<<mem2<<", "<<0<<"\n";
		code_file << "\tje "<<l1<<"\n";
		code_file << "\tmov "<<reg<<", dword "<<1<<"\n";
		code_file << "\tjmp "<<l2<<"\n";
		code_file << l1 <<":\n";
		code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
		code_file << l2 <<":\n";
        update_reg_desc(reg, &instr->res);
	}
}

void logic_or(quad *instr){
    string l1 = "", l2 = "";
    l1 = get_label();
    l2 = get_label();
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);    

	if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
		int a = stoi(instr->arg1.first);
		int b = stoi(instr->arg2.first);
		if(a || b){
			code_file << "\tmov "<< reg <<", dword "<<1<<"\n";
		}
		else{
			code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
		}
        return ;
	}
    string mem2 = get_mem_location(&instr->arg2, 0);

    code_file << "\tcmp "<<reg<<", "<<0<<"\n";
    code_file << "\tjne "<<l1<<"\n";
    code_file << "\tcmp "<<mem2<<", "<<0<<"\n";
    code_file << "\tjne "<<l1<<"\n";
    code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
    code_file << "\tjmp "<<l2<<"\n";
    code_file << l1 <<":\n";
    code_file << "\tmov "<<reg<<", dword "<<1<<"\n";
    code_file << l2 <<":\n";
    update_reg_desc(reg, &instr->res);
}

void bitwise_op(quad* instr){
    string op = instr->op.first;
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);    

    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = 0;
        if(op == "^")      val = (stoi(instr->arg1.first) ^ stoi(instr->arg2.first));
        else if(op == "&")  val = (stoi(instr->arg1.first) & stoi(instr->arg2.first));
        else if(op == "|") val = (stoi(instr->arg1.first) | stoi(instr->arg2.first));
        code_file << "\tmov " << reg <<", " << "dword "<< val << "\n";
        return;
    }
    string instruction = "";
    if(op == "^")      instruction = "xor";
    else if(op == "&") instruction = "and";
    else if(op == "|") instruction = "or";
    
    string mem2 = get_mem_location(&instr->arg2, 0);
    code_file << "\t"<<instruction<< " "<<reg <<", "<<mem2 <<"\n";
    update_reg_desc(reg, &instr->res);
}

void comparison_op(quad* instr){
    string op = instr->op.first;
    string l1 = "", l2 = "";
    l1 = get_label();
    l2 = get_label();
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);    

    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = 0;
        if(op == "==")      val = (stoi(instr->arg1.first) == stoi(instr->arg2.first));
        else if(op == "<")  val = (stoi(instr->arg1.first) < stoi(instr->arg2.first));
        else if(op == "<=") val = (stoi(instr->arg1.first) <= stoi(instr->arg2.first));
        else if(op == ">")  val = (stoi(instr->arg1.first) > stoi(instr->arg2.first));
        else if(op == ">=") val = (stoi(instr->arg1.first) >= stoi(instr->arg2.first));
        else if(op == "!=") val = (stoi(instr->arg1.first) != stoi(instr->arg2.first));

        code_file << "\tmov " << reg <<", " << "dword "<< val << "\n";
        return;
    }
    string jump_instruction = "";
    if(op == "==")      jump_instruction = "je";
    else if(op == "<")  jump_instruction = "jl";
    else if(op == "<=") jump_instruction = "jle";
    else if(op == ">")  jump_instruction = "jg";
    else if(op == ">=") jump_instruction = "jge";
    else if(op == "!=") jump_instruction = "jne";

    string mem2 = get_mem_location(&instr->arg2, 0);

    code_file << "\tcmp "<<reg<<", " << mem2 <<"\n";
    code_file << "\t"<<jump_instruction << " "<<l1<<"\n";
    code_file << "\tmov " << reg <<", " << "dword 0"<<"\n";
    code_file << "\tjmp " << l2 <<"\n";
    code_file << l1 << ":"<<"\n";
    code_file << "\tmov " << reg <<", " << "dword 1"<<"\n";
    code_file << l2 <<":" <<"\n";
    update_reg_desc(reg, &instr->res);
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
                code_file << "\txor eax, eax\n";
                code_file << "\tleave\n";
                code_file << "\tret\n";
            }
            if(instr.op.first[0] == '-') sub_op(&instr);
            if(instr.op.first[0] == '*') mul_op(&instr);
            if(instr.op.first[0] == '/') div_op(&instr);
            if(instr.op.first[0] == '%') mod_op(&instr);
            if(instr.op.first == "RETURN") return_op(&instr);
            if(instr.op.first == "param") params.push_back(instr.arg1);
            if(instr.op.first == "CALL") call_func(&instr);
            if(instr.op.first == "=="  
                    ||instr.op.first == "<" 
                    ||instr.op.first == "<=" 
                    ||instr.op.first == ">" 
                    ||instr.op.first == ">=" 
                    ||instr.op.first == "!=" ) comparison_op(&instr); 

            if(instr.op.first == "&&") logic_and(&instr);
            if(instr.op.first == "||") logic_or(&instr);
            if(instr.op.first == "^" ||  instr.op.first == "&" || instr.op.first == "|") bitwise_op(&instr);
        }
        if(!ended) end_basic_block();
    }
    for(auto it: stringlabels){
        code_file<<"str"<<it.first<<": db "<<it.second<<", 0\n";
    }
}

void end_basic_block(){
    for(auto reg: reg_desc){
        for(auto sym: reg.second){
            if(sym.first[0] == '#' || is_integer(sym.first)) continue;
            cout<<sym.first<<" in " << reg.first<<"\n";
            sym.second->addr_descriptor.reg = "";
            code_file<<"\tmov " << get_mem_location(&sym, 1) <<", "<<reg.first<<"\n";
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
    reg_desc.insert(make_pair("eax", set<qid> () ));
    reg_desc.insert(make_pair("ecx", set<qid> () ));
    reg_desc.insert(make_pair("edx", set<qid> () ));
    reg_desc.insert(make_pair("ebx", set<qid> () ));
    reg_desc.insert(make_pair("esi", set<qid> () ));
    reg_desc.insert(make_pair("edi", set<qid> () ));
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

string get_mem_location(qid* sym, int flag){

    if(is_integer(sym->first)){
        if(flag) return string("dword " + sym->first);
        else return sym->first;
    }

    if(sym->second->addr_descriptor.reg != ""){
        return sym->second->addr_descriptor.reg;
    }

    if(sym->second->heap_mem == 0){
        //Symbol in stack
        ull offset = sym->second->offset;
        ull size = sym->second->size;
        sym->second->addr_descriptor.stack = true;
        return string("[ ebp - " + to_string(offset + size) + " ]");
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
            code_file << "\tmov " << get_mem_location(sym, 1) << ", " << reg <<endl;
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
            code_file << "\tmov " << get_mem_location(&q, 1) << ", " << reg <<endl;
        }
        
    }
    reg_desc[reg].clear();

    code_file << "\tmov " << reg << ", "<< get_mem_location(sym, 1) <<endl;
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

