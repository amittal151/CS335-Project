#include "codegen.h"
#include "3ac.h"
map<string, set<qid> > reg_desc;
map<int ,string> leaders; 
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
        int val = (stoi(instr->arg1.first) + stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
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
        int val = (stoi(instr->arg1.first) - stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
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
        int val = (stoi(instr->arg1.first) * stoi(instr->arg2.first));
        code_file << "\tmov " << get_mem_location(&instr->res, 0) <<", " << "dword "<< val << "\n";
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
    cout<<reg<<"\n";
    for(auto sym: reg_desc[reg]){
        sym.second->addr_descriptor.reg = "";
        cout<<sym.first<<"\n";
        code_file<<"\tmov "<<get_mem_location(&sym, 1)<<", "<<reg<<"\n";
    }
    reg_desc[reg].clear();
}

void call_func(quad *instr){

    for(auto it: reg_desc){
        free_reg(it.first);
    }

    int curr_reg = 0;
    for(int i = params.size()-1; i>=0; i--){
        // free_reg(func_regs[curr_reg]);
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
            
            if(reg_desc.find(mem) == reg_desc.end() && mem.substr(0,5) != "dword") mem = "dword "+mem;
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
        update_reg_desc(reg, &instr->res);        // since reg will still hold y's value, keep y in reg
        reg_desc[reg].insert(instr->arg1);
        instr->arg1.second->addr_descriptor.reg = reg;
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
    code_file << "\tsub esp, "<<func_local_size(name)<<"\n";  // TODO
}


void lshift_op(quad* instr){    // <<
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    string mem2;
    if(is_integer(instr->arg2.first)) mem2 = instr->arg2.first;
    else{
        free_reg("ecx");
        mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\tmov " << "cl" << ", " << mem2 <<"\n";
        mem2 = "cl";
    }
    
    code_file << "\tshl " << reg1 << ", " << mem2 <<"\n";
    update_reg_desc(reg1, &instr->res);
}

void rshift_op(quad* instr){    // >>
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    string mem2;
    if(is_integer(instr->arg2.first)) mem2 = instr->arg2.first;
    else{
        free_reg("ecx");
        mem2 = get_mem_location(&instr->arg2, 0);
        code_file << "\tmov " << "cl" << ", " << mem2 <<"\n";
        mem2 = "cl";
    }
    
    code_file << "\tshr " << reg1 << ", " << mem2 <<"\n";
    update_reg_desc(reg1, &instr->res);
}

void unary_op(quad* instr){
    // cout<<"vfvfewvdcdwc";
    string op = instr->op.first;
    // cout<<instr->arg1.second->addr_descriptor.reg;
   
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    
    // cout<<mem<<" ";
    string instruction = "";
    if(op[2] == 'P'){
        if(op == "++P")      instruction = "inc";
        else if(op == "--P") instruction = "dec";
        code_file << "\t"<<instruction<< " "<<reg <<"\n";
        // string mem = get_mem_location(&instr->arg1, -1);
        // code_file << "\tmov " << mem << ", " <<  reg<<"\n";
        update_reg_desc(reg, &instr->res);
        
    }
    else if(op[2] == 'S'){
        if(op == "++S")      instruction = "inc";
        else if(op == "--S") instruction = "dec";
        update_reg_desc(reg, &instr->res);
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        code_file << "\t"<<instruction<< " "<<reg1 <<"\n";
        // string mem = get_mem_location(&instr->arg1, -1);
        // code_file << "\tmov " << mem << ", " <<  reg1<<"\n";
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
        string reg = get_mem_location(&instr->arg2, 0);

        code_file << "\tcmp " << reg <<", " << "dword 0"<<"\n";
        code_file << "\tjne "<<leaders[id]<<"\n";
    }
    else{
        code_file << "\tjmp " << leaders[id] <<"\n";
    }
}



void genCode(){
    // Prints final code to be generated in asm file
    findBasicBlocks();
    initializeRegs();
    nextUse();
    
    gen_data_section();
    starting_code();

    for(auto it: leaders){
        cout<<it.first<<" "<<it.second<<"\n";
    }
    cout<<"\n";

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
                    ||instr.op.first == "unary-" ) unary_op(&instr);
            else if(instr.op.first[0] == '+')    add_op(&instr);
            else if(instr.op.first == "=")   assign_op(&instr);
            else if(instr.op.first.substr(0, 5) == "FUNC_" && instr.op.first[(instr.op.first.size() - 3)] == 'd'){
                ended = 1;
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
                ended = 1;
                return_op(&instr);
            }
            else if(instr.op.first == "param") params.push_back(instr.arg1);
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
                ended=1;
            }
            
            
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
            if(sym->first[0] == '#' || is_integer(sym->first)) continue;
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
    }
    
    for(auto it = reg_desc.begin(); it != reg_desc.end(); it++){
        it->second.erase(*sym);
    }
    
    reg_desc[reg].clear();
    reg_desc[reg].insert(*sym);          // x = y + z; 
    cout<<sym->first<<" in "<<reg<<"\n";
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
        return sym->second->addr_descriptor.reg;
    }

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
        if( it.second.find(*sym2) != it.second.end()){
            // skip the reg containing second argument for an instruction
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

