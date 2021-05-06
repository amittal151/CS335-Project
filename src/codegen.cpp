#include "codegen.h"
#include "3ac.h"
map<string, set<qid> > reg_desc;
map<int ,string> leaders; 
stack<qid>  params; // stores the parameters as soon as we encounter first param
map<int, string> stringlabels;
map<int, int> pointed_by; 
map<qid, int> addr_pointed_to;

int string_counter = 0; 
int label_counter = 0;

set<string> exclude_this;

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
        int val = (stoi(instr->arg1.first) + stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        // arg1 -> reg1
        int val = instr->arg1.second->is_derefer;
        while(val--){
            code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
        }

        string mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\tadd " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void sub_op(quad* instr){
    // x = 2 - 3
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = (stoi(instr->arg1.first) - stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
    }
    // x = 1 - b
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);

        if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";

        string mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\tsub " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void mul_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = (stoi(instr->arg1.first) * stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);

        if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";

        string mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\timul " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void div_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        // TODO check  div by zero
        int val = (stoi(instr->arg1.first) / stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
    }
    else{
        free_reg("eax");
        free_reg("edx");
        code_file<<"\tmov eax"<<", "<<get_mem_location(&instr->arg1, 0)<<"\n";
        reg_desc["eax"].insert(instr->arg2);
        reg_desc["edx"].insert(instr->arg2);
        
        exclude_this.insert("edx");
        exclude_this.insert("eax");
        string reg2 = getReg(&instr->arg2, &instr->res, &empty_var, instr->idx);
        if(instr->arg2.second->is_derefer) code_file<<"\tmov "<<reg2<<", [ "<<reg2<<" ]\n";
        exclude_this.clear(); 

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
        int val = (stoi(instr->arg1.first) % stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
    }
    else{
        free_reg("eax");
        free_reg("edx");
        code_file<<"\tmov eax"<<", "<<get_mem_location(&instr->arg1, 0)<<"\n";
        reg_desc["eax"].insert(instr->arg2);
        reg_desc["edx"].insert(instr->arg2);
        string reg2 = getReg(&instr->arg2, &instr->res, &empty_var, instr->idx);
        if(instr->arg2.second->is_derefer) code_file<<"\tmov "<<reg2<<", [ "<<reg2<<" ]\n";

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
        // clear_regs();
        string mem = get_mem_location(&instr->arg1, 1);
        if(mem != "eax") code_file<<"\tmov eax, "<<mem<<"\n";
        code_file<<"\tleave\n";
        code_file<<"\tret\n";
    }
    else{
        // clear_regs();
        code_file<<"\txor eax, eax\n";
        code_file<<"\tleave\n";
        code_file<<"\tret\n";
    }
}

void clear_regs(){
    for(auto reg = reg_desc.begin(); reg != reg_desc.end(); reg++){
        reg->second.clear();
    }
}


// free a specific register
// eg for div we need eax, edx
void free_reg(string reg){
    for(auto sym: reg_desc[reg]){
        if(is_integer(sym.first)) continue;
        sym.second->addr_descriptor.reg = "";
        code_file<<"\tmov "<<get_mem_location(&sym, 1)<<", "<<reg<<"\n";
    }
    reg_desc[reg].clear();
}

void call_func(quad *instr){

    for(auto it: reg_desc){
        free_reg(it.first);
    }

    int curr_reg = 0;
    int i = stoi(instr->arg2.first);
    int sz = i;

    

    while(i>0){
        // free_reg(func_regs[curr_reg]);
        if(params.top().first[0] == '\"'){
            string temp = params.top().first;
            temp[0] = '`', temp[temp.length()-1] = '`';
            stringlabels.insert({string_counter, temp});
            // code_file<<"\tmov "<<func_regs[curr_reg]<<", str"<<string_counter<<"\n";
            code_file<<"\tpush str"<<string_counter<<"\n";
            string_counter++;
        }
        else if(params.top().second->is_derefer){
            string mem;
            if(params.top().second->addr_descriptor.reg != "") mem = get_mem_location(&params.top(), 1);
            else{
                mem = getReg(&params.top(), &empty_var, &empty_var, -1);
                mem = "[ " + mem + " ]";
            }
            code_file<<"\tpush dword "<<mem<<"\n";
        }
        else{
            // code_file<<"\tmov "<<func_regs[curr_reg]<<", "<<get_mem_location(&it, 1)<<"\n";
            string mem = get_mem_location(&params.top(), 1);
            
            if(reg_desc.find(mem) == reg_desc.end() && mem.substr(0,5) != "dword") mem = "dword "+mem;
            code_file<<"\tpush "<<mem<<"\n";
            
        }
        i--;
        params.pop();
        // curr_reg++;
    }
    
    code_file<<"\tcall "<<instr->arg1.first<<"\n";
    
    // Clear args from stack
    code_file<<"\tadd esp, "<<4*sz<<"\n";
    reg_desc["eax"].insert(instr->res);
    instr->res.second->addr_descriptor.reg = "eax";

   
}

void assign_op(quad* instr){
    // *x = something
    if(instr->res.second->is_derefer){
        string res_mem;
        if(instr->res.second->addr_descriptor.reg != "") res_mem = get_mem_location(&instr->res, 0);
        else{
            res_mem = getReg(&instr->res, &empty_var, &empty_var, -1);
            res_mem = "[ " + res_mem + " ]";
        }
        string arg1_mem = getReg(&instr->arg1, &empty_var, &empty_var, -1);
        code_file<<"\tmov "<<res_mem<<", "<<arg1_mem<<"\n";
    }
    // x = 1
    else if(is_integer(instr->arg1.first)){
        // string reg = getReg(instr->res, qid("", NULL), qid("", NULL), instr->idx);
        string mem = get_mem_location(&instr->res, 1);
        code_file << "\tmov "<< mem << ", dword "<< stoi(instr->arg1.first) <<endl;
    } 
    // x = y
    else{
        string reg = getReg(&instr->arg1, &instr->res, &empty_var, instr->idx);
        update_reg_desc(reg, &instr->res);        // since reg will still hold y's value, keep y in reg
        reg_desc[reg].insert(instr->arg1);
        instr->arg1.second->addr_descriptor.reg = reg;
        
        if(instr->res.second->type[instr->res.second->type.length()-1] == '*'){
            pointed_by[addr_pointed_to[instr->arg1]] = 1;
        }
        if(pointed_by[instr->res.second->offset]){
            string reg_stored = instr->res.second->addr_descriptor.reg;
            instr->res.second->addr_descriptor.reg = "";
            reg_desc[reg_stored].erase(instr->res);
            code_file<<"\tmov "<<get_mem_location(&instr->res, 0)<<", "<<reg_stored<<"\n";
        }
    }
}

void gen_func_label(quad* instr){
    string s = "";
    for(int i=5;i<instr->op.first.size(); i++){
        if(instr->op.first[i] == ' ')break;
        s += instr->op.first[i];
    }
    string name = "";
    for(int i = 5; i<instr->op.first.length(); i++){
        if(instr->op.first[i] == ' ') break;
        name+=instr->op.first[i];
    }
    code_file << s << " :\n";
    code_file << "\tpush ebp\n";
    code_file << "\tmov ebp, esp\n"; 
    code_file << "\tsub esp, "<<func_local_size(name)<<"\n";

    pointed_by.clear();
}


void lshift_op(quad* instr){    // <<
    exclude_this.insert("ecx");
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    exclude_this.clear();
    if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
    string mem2;
    // if(is_integer(instr->arg2.first)) mem2 = instr->arg2.first;
    // if(is_integer(instr->arg1.first))
    // else{
    free_reg("ecx");
    mem2 = get_mem_location(&instr->arg2, 0);
    code_file << "\tmov " << "ecx" << ", " << mem2 <<"\n";
    mem2 = "cl";
    // }
    
    code_file << "\tshl " << reg1 << ", " << mem2 <<"\n";
    update_reg_desc(reg1, &instr->res);
}

void rshift_op(quad* instr){    // >>
    exclude_this.insert("ecx");
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    exclude_this.clear();
    if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
    string mem2;
    // if(is_integer(instr->arg2.first)) mem2 = instr->arg2.first;
    // if(is_integer(instr->arg1.first))
    // else{
    free_reg("ecx");
    mem2 = get_mem_location(&instr->arg2, 0);
    code_file << "\tmov " << "ecx" << ", " << mem2 <<"\n";
    mem2 = "cl";
    // }
    
    code_file << "\tshr " << reg1 << ", " << mem2 <<"\n";
    update_reg_desc(reg1, &instr->res);
}

void unary_op(quad* instr){
    // cout<<"vfvfewvdcdwc";
    string op = instr->op.first;
    // cout<<instr->arg1.second->addr_descriptor.reg;
   
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";

    
    // cout<<mem<<" ";
    string instruction = "";
    if(op[2] == 'P'){
        if(op == "++P")      instruction = "inc";
        else if(op == "--P") instruction = "dec";
        code_file << "\t"<<instruction<< " "<<reg <<"\n";
        string mem = get_mem_location(&instr->arg1, -1);
        code_file << "\tmov " << mem << ", " <<  reg<<"\n";
        update_reg_desc(reg, &instr->res);
        
    }
    else if(op[2] == 'S'){
        if(op == "++S")      instruction = "inc";
        else if(op == "--S") instruction = "dec";
        update_reg_desc(reg, &instr->res);
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";

        code_file << "\t"<<instruction<< " "<<reg1 <<"\n";
        string mem = get_mem_location(&instr->arg1, -1);
        code_file << "\tmov " << mem << ", " <<  reg1<<"\n";
    }
    else if(op =="~" ) {
        instruction = "not";
        code_file << "\t"<<instruction<< " "<<reg <<"\n";        
        update_reg_desc(reg, &instr->res);
    }
    else if(op == "unary-"){
        instruction = "neg";
        code_file << "\t"<<instruction<< " "<<reg <<"\n";        
        update_reg_desc(reg, &instr->res);
    }
    else if(op == "unary+"){
        // instruction = "neg";
        // code_file << "\t"<<instruction<< " "<<reg <<"\n";        
        update_reg_desc(reg, &instr->res);
    }
    else if(op == "!"){
        string l1 = get_label();
        string l2 = get_label();
        code_file << "\tcmp "<<reg<<", dword "<<0<<"\n";  //dword inserted
		code_file << "\tje "<<l1<<"\n";
		code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
		code_file << "\tjmp "<<l2<<"\n";
		code_file << l1 <<":\n";
		code_file << "\tmov "<<reg<<", dword "<<1<<"\n";
		code_file << l2 <<":\n";
        update_reg_desc(reg, &instr->res);
    }
    

}

void logic_and(quad *instr){
	
	if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
		int a = stoi(instr->arg1.first);
		int b = stoi(instr->arg2.first);
        string reg = get_mem_location(&instr->res, 1);
		if(a && b){
			code_file << "\tmov "<<reg<<", dword "<<1<<"\n";
		}
		else{
			code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
		}
	}
	else{
        string l1 = "", l2 = "";
        l1 = get_label();
        l2 = get_label();
        string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);    
        if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";

		string mem2 = get_mem_location(&instr->arg2, 0);
	
		code_file << "\tcmp "<<reg<<", dword "<<0<<"\n";
		code_file << "\tje "<<l1<<"\n";
		code_file << "\tcmp "<<mem2<<", dword "<<0<<"\n";
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
    
	if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
		int a = stoi(instr->arg1.first);
		int b = stoi(instr->arg2.first);
        string reg = get_mem_location(&instr->res, 1);
		if(a || b){
			code_file << "\tmov "<< reg <<", dword "<<1<<"\n";
		}
		else{
			code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
		}
	}
    else{
        string l1 = "", l2 = "";
        l1 = get_label();
        l2 = get_label();
        string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);    
        if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";

        string mem2 = get_mem_location(&instr->arg2, 0);

        code_file << "\tcmp "<<reg<<", dword "<<0<<"\n";
        code_file << "\tjne "<<l1<<"\n";
        code_file << "\tcmp "<<mem2<<", dword "<<0<<"\n";
        code_file << "\tjne "<<l1<<"\n";
        code_file << "\tmov "<<reg<<", dword "<<0<<"\n";
        code_file << "\tjmp "<<l2<<"\n";
        code_file << l1 <<":\n";
        code_file << "\tmov "<<reg<<", dword "<<1<<"\n";
        code_file << l2 <<":\n";
        update_reg_desc(reg, &instr->res);
    }
}

void bitwise_op(quad* instr){
    string op = instr->op.first;
        

    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = 0;
        if(op == "^")      val = (stoi(instr->arg1.first) ^ stoi(instr->arg2.first));
        else if(op == "&")  val = (stoi(instr->arg1.first) & stoi(instr->arg2.first));
        else if(op == "|") val = (stoi(instr->arg1.first) | stoi(instr->arg2.first));
        string mem = get_mem_location(&instr->res, 1);
        code_file << "\tmov " << mem <<", " << "dword "<< val << "\n";
        return;
    }
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";

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
        

    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = 0;
        if(op == "==")      val = (stoi(instr->arg1.first) == stoi(instr->arg2.first));
        else if(op == "<")  val = (stoi(instr->arg1.first) < stoi(instr->arg2.first));
        else if(op == "<=") val = (stoi(instr->arg1.first) <= stoi(instr->arg2.first));
        else if(op == ">")  val = (stoi(instr->arg1.first) > stoi(instr->arg2.first));
        else if(op == ">=") val = (stoi(instr->arg1.first) >= stoi(instr->arg2.first));
        else if(op == "!=") val = (stoi(instr->arg1.first) != stoi(instr->arg2.first));
        string mem = get_mem_location(&instr->res, 1);
        code_file << "\tmov " << mem <<", " << "dword "<< val << "\n";
        return;
    }

    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";

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

void goto_op(quad* instr){
    end_basic_block();
    int id = instr->idx;
    // cout<<id<<"-----\n";
    if(instr->arg1.first == "IF"){
        string reg = get_mem_location(&instr->arg2, 1);
        if(is_integer(instr->arg2.first)) reg = getReg(&instr->arg2, &empty_var, &empty_var, instr->idx);
        code_file << "\tcmp " << reg <<", " << "dword 0"<<"\n";
        code_file << "\tjne "<<leaders[id]<<"\n";
    }
    else{
        code_file << "\tjmp " << leaders[id] <<"\n";
    }
}

void pointer_op(quad* instr){
    if(instr->op.first == "unary&"){
        if(is_integer(instr->arg1.first)){
            // Give error
        }
        free_reg("eax");
        if(instr->arg1.second->addr_descriptor.reg != ""){
            string reg = instr->arg1.second->addr_descriptor.reg;
            reg_desc[reg].erase(instr->arg1);
            instr->arg1.second->addr_descriptor.reg = "";
            code_file<<"\tmov "<<get_mem_location(&instr->arg1, 0)<<", "<<reg<<"\n";
        }
        string mem = get_mem_location(&instr->arg1, 0);

        if(!instr->arg1.second->is_derefer) code_file<<"\tlea eax, "<<mem<<"\n";
        else code_file<<"\tmov eax, "<<mem<<"\n";
        pointed_by[instr->arg1.second->offset] = 0;
        addr_pointed_to[instr->res] = instr->arg1.second->offset;
        update_reg_desc("eax", &instr->res);
    }
    else{
        // #v0 = *a
        free_reg("eax");
        string mem ;
        mem = get_mem_location(&instr->arg1, 0);  
        
        // if(instr->arg1.second->type[instr->arg1.second->type.length()-1] == '*') mem = get_mem_location(&instr->arg1, -2);
        // else mem = get_mem_location(&instr->arg1, 0);

        // if(reg_desc.find(mem) != reg_desc.end()) mem = "[ " + mem + " ]";
        // code_file<<"PATA NHI KYA HOGA HAMAR :(\n";
        code_file<<"\tmov eax, "<<mem<<"\n";
        update_reg_desc("eax", &instr->res);
        instr->res.second->is_derefer = instr->arg1.second->is_derefer + 1;
    }
}

void ptr_op(quad* instr){

}

void member_access(quad* instr){
    if(!instr->arg1.second->is_derefer){
        instr->res.second->offset = instr->arg2.second->offset;
        // cout<<"offset "<<instr->res.second->offset<<"\n";
        // string reg
    }
    else{
        
    }
}

void array_op(quad* instr){
    // if(instr->arg1.second->array_dims.size() == 0){
        string reg = getReg(&instr->res, &instr->arg2, &empty_var, instr->idx);
        string mem;
        
        if(instr->arg1.first[0] != '#') {    //First index    
            mem = get_mem_location(&instr->arg1, -1);
            code_file<<"\tlea "<<reg<<", "<<mem<<"\n";
        }
        else {
            mem = get_mem_location(&instr->arg1, 0);
            code_file<<"\tmov "<<reg<<", "<<mem<<"\n";
        }
        exclude_this.insert(reg);
        string reg1 = getReg(&instr->arg2, &empty_var, &empty_var, instr->idx);
        
        if(instr->arg1.second->array_dims.empty()) code_file<<"\timul "<<reg1<<", "<<4<<"\n";
        else code_file<<"\timul "<<reg1<<", "<<4*instr->arg1.second->array_dims[0]<<"\n";
       
        code_file<<"\tadd "<<reg<<", "<<reg1<<"\n";
        if(instr->arg1.second->array_dims.empty()) instr->res.second->is_derefer = 1;

        exclude_this.clear();
        reg_desc[reg1].erase(instr->arg2);
        instr->arg2.second->addr_descriptor.reg = "";
        
        // Do  not touch this shit else it will break the whole shit
        update_reg_desc(reg, &instr->res);
        
    // }
    // else{                
    //     // allocate register to result first (only first time)
    //     string reg = getReg(&instr->res, &instr->arg2, &empty_var, instr->idx);
    //     string mem;
        
    //     // Store address of Array name into a register for the first indexing
    //     // Later, we need to mov the offsetted memory into register only!
    //     if(instr->arg1.first[0] != '#') {
    //         mem = get_mem_location(&instr->arg1, -1);
    //         code_file<<"\tlea "<<reg<<", "<<mem<<"\n";
    //     }
    //     else {
    //         mem = get_mem_location(&instr->arg1, 0);
    //         code_file<<"\tmov "<<reg<<", "<<mem<<"\n";
    //     }
    //     exclude_this.insert(reg);
    //     string reg1 = getReg(&instr->arg2, &empty_var, &empty_var, instr->idx);
    //     code_file<<"\timul "<<reg1<<", "<<4*instr->arg1.second->array_dims[0]<<"\n";
    //     code_file<<"\tadd "<<reg<<", "<<reg1<<"\n";
        
        
    //     exclude_this.clear();
    //     reg_desc[reg1].erase(instr->arg2);
    //     instr->arg2.second->addr_descriptor.reg = "";
        
    //     update_reg_desc(reg, &instr->res);
        
    // }
}

void genCode(){
    // Prints final code to be generated in asm file
    findBasicBlocks();
    initializeRegs();
    nextUse();
    
    gen_data_section();
    starting_code();

    // for(auto it: leaders){
    //     cout<<it.first<<" "<<it.second<<"\n";
    // }
    // cout<<"\n";

    for (auto it=leaders.begin(); it != leaders.end(); it++){
        code_file << it->second <<":\n";
        auto it1 = it;
        it1++;
        if(it1 == leaders.end()) break;
        int ended = 0;
        int start = it->first;
        int end = it1->first;
        
        for(int idx=start; idx < end; idx++){
            
            quad instr = code[idx];
            if(instr.op.first.substr(0, 5) == "FUNC_" && instr.op.first[(instr.op.first.size() - 3)] == 't'){
                gen_func_label(&instr);
            }
            else if(instr.op.first.substr(0,2) == "++"  
                    ||instr.op.first.substr(0,2) == "--" 
                    ||instr.op.first == "!" 
                    ||instr.op.first == "~" 
                    ||instr.op.first == "unary-" 
                    ||instr.op.first == "unary+") unary_op(&instr);
            else if(instr.op.first == "unary&" || instr.op.first == "unary*") pointer_op(&instr);
            else if(instr.op.first[0] == '+')    add_op(&instr);
            else if(instr.op.first == "=")   assign_op(&instr);
            else if(instr.op.first.substr(0, 5) == "FUNC_" && instr.op.first[(instr.op.first.size() - 3)] == 'd'){
                // ended = 1;
                end_basic_block();
                code_file << "\txor eax, eax\n";
                code_file << "\tleave\n";
                code_file << "\tret\n";
                clear_regs();
                
            }
            else if(instr.op.first[0] == '-') sub_op(&instr);
            else if(instr.op.first[0] == '*') mul_op(&instr);
            else if(instr.op.first[0] == '/') div_op(&instr);
            else if(instr.op.first[0] == '%') mod_op(&instr);
            else if(instr.op.first == "RETURN"){
                // ended = 1;
                return_op(&instr);
            }
            else if(instr.op.first == "param") params.push(instr.arg1);
            else if(instr.op.first == "CALL") call_func(&instr);
            else if(instr.op.first == "=="  
                    ||instr.op.first == "<" 
                    ||instr.op.first == "<=" 
                    ||instr.op.first == ">" 
                    ||instr.op.first == ">=" 
                    ||instr.op.first == "!=" ) comparison_op(&instr); 

            else if(instr.op.first == "&&") logic_and(&instr);
            else if(instr.op.first == "||") logic_or(&instr);
            else if(instr.op.first.substr(0,2) == "<<") lshift_op(&instr);
            else if(instr.op.first.substr(0,2) == ">>") rshift_op(&instr);
            else if(instr.op.first[0] == '^' ||  instr.op.first[0] == '&' || instr.op.first[0] == '|') bitwise_op(&instr);
            else if(instr.op.first == "GOTO") {
                // cout<<instr.idx <<"---\n";
                // print3AC_code();
                
                goto_op(&instr);
                // ended=1;
            }
            else if(instr.op.first == "PTR_OP") ptr_op(&instr);
            else if(instr.op.first == "member_access") member_access(&instr);
            else if(instr.op.first == "[ ]") array_op(&instr);
            
            
        }
        if(!ended) end_basic_block();
    }
    for(auto it: stringlabels){
        code_file<<"str"<<it.first<<": db "<<it.second<<", 0\n";
    }
}

void end_basic_block(){
    for(auto reg = reg_desc.begin();reg!=reg_desc.end();reg++){
        for(auto sym =reg->second.begin() ;sym!=reg->second.end(); sym++){
            if( is_integer(sym->first)) continue;
            sym->second->addr_descriptor.reg = "";
            qid tem = *sym;
            code_file<<"\tmov " << get_mem_location(&tem, 0) <<", "<<reg->first<<"\n";
        }
        reg->second.clear();
    }
}


void update_reg_desc(string reg, qid* sym){
    for(auto it = reg_desc[reg].begin();it != reg_desc[reg].end(); it++){
        it->second->addr_descriptor.reg = "";
        qid temp = *it;
    }
    
    for(auto it = reg_desc.begin(); it != reg_desc.end(); it++){
        it->second.erase(*sym);
    }
    
    reg_desc[reg].clear();
    reg_desc[reg].insert(*sym);          // x = y + z; 
    // cout<<sym->first<<" in "<<reg<<"\n";
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


void freeDeadTemp(int idx){
    // free registers allocated to Dead temporaries
    
    for(auto it = reg_desc.begin(); it != reg_desc.end(); it++){
        vector<qid> temp;
        for(auto sym : it->second){
            if(sym.second->next_use < idx && sym.second->next_use != -1){
                temp.push_back(sym);
                sym.second->addr_descriptor.reg = "";
            }
        }
        for (auto v : temp){
            it->second.erase(v);
        }
    }
}

// -1: only mem required
// 1: for instructions which require size
// 0: otherwise
string get_mem_location(qid* sym, int flag){

    if(is_integer(sym->first)){
        if(flag) return string("dword " + sym->first);
        else return sym->first;
    }

    if(sym->second->addr_descriptor.reg != "" && flag!=-1){
        if(!sym->second->is_derefer || flag == -2) return sym->second->addr_descriptor.reg;
        else return "[ " + sym->second->addr_descriptor.reg + " ]";
    }

    // if(sym->second->is_derefer){
    //     string reg = getReg(sym, &empty_var, &empty_var, -1);
    //     return "[ " + reg + " ]";
    // }

    if(sym->second->heap_mem == 0){
        //Symbol in stack
        int offset = sym->second->offset;
        int size = sym->second->size;
        sym->second->addr_descriptor.stack = true;
        if(offset >= 0) return string("[ ebp - " + to_string(offset + size) + " ]");
        else{
            offset=-offset;
            return string("[ ebp + "+to_string(offset) +" ]");
        }
    }
    
    sym->second->addr_descriptor.stack = false;
    sym->second->addr_descriptor.heap = true;
    return string("[ " + to_string(sym->second->heap_mem) + " ]");
}

string getReg(qid* sym, qid* result, qid* sym2, int idx){
    // Allocates best register if available
    // freeDeadTemp(idx);

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
        if( it.second.find(*sym2) != it.second.end() || exclude_this.find(it.first) != exclude_this.end()){
            // skip the reg containing second argument for an instruction
            continue;
        }
        if (it.second.size() < mn){
            mn =  it.second.size();
            reg = it.first; 
        }
    } 
    assert(reg != "");

    free_reg(reg);

    code_file << "\tmov " << reg << ", "<< get_mem_location(sym, 1) <<endl;
    sym->second->addr_descriptor.reg = reg;
    reg_desc[reg].insert(*sym);
    // if(s)
    return reg;
}


void nextUse(){
    for(auto it=leaders.begin(); it != leaders.end(); it++){
        auto it1 = it;
        it1++;
        if(it1 == leaders.end()) break;

        for(int i= (it1->first)-1; i>= (it->first); i--){
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

    for (int i=0;i< (int)code.size(); i++){

        if (i == 0){
            leaders.insert(make_pair(i, get_label()));
            continue;
        }
        if(code[i].op.first.substr(0, 5) == "FUNC_"){
                if(code[i].op.first[code[i].op.first.length()-3] == 't') leaders.insert(make_pair(i, get_label()));
                else if(i+1 != code.size()) leaders.insert(make_pair(i+1, get_label()));
        }
        else if(code[i].op.first == "GOTO"){
            leaders.insert(make_pair(code[i].idx, get_label()));
            leaders.insert(make_pair(i+1, get_label()));
        }   
    }
    leaders.insert(make_pair(code.size(), get_label()));
}

