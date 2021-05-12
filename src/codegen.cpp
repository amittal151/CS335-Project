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
int arg_size = 0;

set<string> exclude_this;

qid empty_var("", NULL);

extern vector<quad> code;
extern ofstream code_file;

string get_label(){
    return "L" +to_string(label_counter++);
}

void gen_data_section(){
    code_file << "extern printf\n";
    code_file << "extern scanf\n";
    code_file << "extern malloc\n";
    code_file << "extern calloc\n";
    code_file << "extern free\n";
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


void add_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = (stoi(instr->arg1.first) + stoi(instr->arg2.first));
        string str = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
        code_file << "\tmov " << str <<", " << "dword "<< val << "\n";
    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);    // reg - mem - [ reg_temp ]
        //free_reg(reg1);
        if(instr->arg1.second->is_derefer){
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg1<<endl;
            code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
        }
        code_file << "\tadd " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void sub_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = (stoi(instr->arg1.first) - stoi(instr->arg2.first));
        string str = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
        code_file << "\tmov " << str <<", " << "dword "<< val << "\n";
    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);    // reg - mem - [ reg_temp ]
        
        if(instr->arg1.second->is_derefer){
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg1<<endl;
            code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
        }
        code_file << "\tsub " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void mul_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = (stoi(instr->arg1.first) * stoi(instr->arg2.first));
        string str = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
        code_file << "\tmov " << str <<", " << "dword "<< val << "\n";
    }
    else{
        string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);    // reg - mem - [ reg_temp ]
        
        if(instr->arg1.second->is_derefer){
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg1<<endl;
            code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
        }
        code_file << "\timul " << reg1 << ", " << mem2 <<endl;
        update_reg_desc(reg1, &instr->res);
    }
}

void div_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        // TODO check  div by zero
        int val = (stoi(instr->arg1.first) / stoi(instr->arg2.first));
        string str = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
        code_file << "\tmov " << str <<", " << "dword "<< val << "\n";
    }
    else{
        free_reg("eax");
        free_reg("edx");
        string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 0);
        code_file<<"\tmov eax"<<", "<< str <<"\n";
        reg_desc["eax"].insert(instr->arg1);
        reg_desc["edx"].insert(instr->arg1);
        
        exclude_this.insert("edx");
        exclude_this.insert("eax");
        string reg2 = getReg(&instr->arg2, &instr->res, &empty_var, instr->idx);
        if(instr->arg2.second->is_derefer){ 
            string str = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg2<<endl;
            code_file<<"\tmov "<<reg2<<", [ "<<reg2<<" ]\n";
        }
        exclude_this.clear(); 

        code_file<<"\tcdq\n";
        code_file<<"\tidiv "<<reg2<<"\n";
        // if(reg_desc.find(instr->res.second->addr_descriptor.reg) != reg_desc.end()){
        //     reg_desc[instr->res.second->addr_descriptor.reg].erase(instr->res);
        // }
        instr->res.second->addr_descriptor.reg = "eax";
        reg_desc["eax"].clear();
        reg_desc["edx"].clear();
        reg_desc["eax"].insert(instr->res);
    }
}

void mod_op(quad* instr){
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int val = (stoi(instr->arg1.first) % stoi(instr->arg2.first));
        string str = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
        code_file << "\tmov " << str <<", " << "dword "<< val << "\n";
    }
    else{
        free_reg("eax");
        free_reg("edx");
        string str = get_mem_location(&instr->arg1,&instr->arg2, instr->idx, 0);
        code_file<<"\tmov eax"<<", "<< str <<"\n";
        reg_desc["eax"].insert(instr->arg1);
        reg_desc["edx"].insert(instr->arg1);
        string reg2 = getReg(&instr->arg2, &instr->res, &empty_var, instr->idx);
        if(instr->arg2.second->is_derefer){
            string str = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg2<<endl;
            code_file<<"\tmov "<<reg2<<", [ "<<reg2<<" ]\n";
        }

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
        if(typeLookup(instr->arg1.second->type)){
            
            for(auto it: reg_desc){
                free_reg(it.first);
            }

            string reg1 = getTemporaryReg(&empty_var, instr->idx);
            
            exclude_this.insert(reg1);
            string reg2 = getTemporaryReg(&empty_var, instr->idx);
            exclude_this.clear();
            
            code_file<<"\tmov "<<reg1<<", [ ebp + "<<arg_size<<" ]\n";
            
            int struct_size = getStructsize(instr->arg1.second->type);
            int struct_offset = instr->arg1.second->offset;
            // sym_table* struct_table = typeTable(instr->arg1.second->type);
            if(instr->arg1.second->offset < 0){
                for(int i = 0; i<struct_size; i+=4){
                    code_file<<"\tmov "<<reg2<<", [ ebp + "<<abs(struct_offset) - i<<" ]\n";
                    code_file<<"\tmov [ "<<reg1<<" + "<<struct_size - i - 4<<" ], "<<reg2<<"\n";
                }
            }
            else{
                cout<<struct_size<<" "<<struct_offset<<" HERE\n";
                for(int i = 0; i<struct_size; i+=4){
                    code_file<<"\tmov "<<reg2<<", [ ebp - "<<struct_offset + 4 + i<<" ]\n";
                    code_file<<"\tmov [ "<<reg1<<" + "<<struct_size - i - 4<<" ], "<<reg2<<"\n";
                }
            }
            code_file<<"\tleave\n";
            code_file<<"\tret\n";
        }
        else{
            string mem = get_mem_location(&instr->arg1, &empty_var, instr->idx, 1);
            if(mem != "eax") code_file<<"\tmov eax, "<<mem<<"\n";
            code_file<<"\tleave\n";
            code_file<<"\tret\n";
        }
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

// reg - a, mem

void free_reg(string reg){
    // code_file<<"reg: "<<reg<<"\n";
    for(auto sym: reg_desc[reg]){
        if(is_integer(sym.first)) continue;
        sym.second->addr_descriptor.reg = "";
        string str = get_mem_location(&sym, &empty_var, -1, -1);
        code_file<<"\tmov "<< str <<", "<<reg<<"\n";
        // code_file<<"; "<<sym.first<<"\n";
    }
    // code_file<<"\n";
    reg_desc[reg].clear();
}

void call_func(quad *instr){

    for(auto it: reg_desc){
        free_reg(it.first);
    }

    int curr_reg = 0;
    int i = stoi(instr->arg2.first);
    int sz = i;

    sym_entry* func_entry = lookup(instr->arg1.first);
    string ret_type = "";
    if(func_entry) ret_type = func_entry->type.substr(5, func_entry->type.length()-5);
    
    if(typeLookup(ret_type)){
        // cout<<"HERE\n";
        code_file<<"\tlea eax, "<<get_mem_location(&instr->res, &empty_var, -1, -1)<<"\n";
        code_file<<"\tpush eax\n";
    }

    while(i>0){
        // free_reg(func_regs[curr_reg]);
        if(params.top().first[0] == '\"'){
            
            stringlabels.insert({string_counter, params.top().first});
            // code_file<<"\tmov "<<func_regs[curr_reg]<<", str"<<string_counter<<"\n";
            code_file<<"\tpush str"<<string_counter<<"\n";
            string_counter++;
        }
        else if(params.top().second->is_derefer){
            string mem;
            mem = get_mem_location(&params.top(), &empty_var, instr->idx, 1);

            code_file<<"\tpush dword "<<mem<<"\n";
        }
        else if(params.top().second->isArray){
            string str = get_mem_location(&params.top(), &empty_var, instr->idx, 1);
            code_file<<"\tlea eax, "<< str <<"\n";
            code_file<<"\tpush eax\n";
        }
        else if(typeLookup(params.top().second->type)){
            int type_size = getSize(params.top().second->type), type_offset = params.top().second->offset;
            if(type_offset > 0){
                for(int i = type_offset; i<type_size + type_offset; i+=4){
                    code_file<<"\tpush dword [ ebp - "<<i+4<<" ]\n";
                }
            }
            else{
                for(int i = 0; i<type_size; i+=4){
                    code_file<<"\tpush dword [ ebp + "<<abs(type_offset+i)<<" ]\n";
                }
            }
                // for(int i = 0; i<type_size; i+=4){
                //     int curr_offset = 
                // }
                // cout<<type_size<<" "<<type_offset<<"\n";
        }
        else{
            // code_file<<"\tmov "<<func_regs[curr_reg]<<", "<<get_mem_location(&it, 1)<<"\n";
            string mem = get_mem_location(&params.top(), &empty_var, instr->idx, 1);
            
            if(reg_desc.find(mem) == reg_desc.end() && mem.substr(0,5) != "dword") mem = "dword "+mem;
            code_file<<"\tpush "<<mem<<"\n";
            
        }
        i--;
        params.pop();
        // curr_reg++;
    }
    
    code_file<<"\tcall "<<instr->arg1.first<<"\n";
    
    // Clear args from stack
    
    if(!typeLookup(ret_type)){
        reg_desc["eax"].insert(instr->res);
        instr->res.second->addr_descriptor.reg = "eax";
    }
    else sz++;

    code_file<<"\tadd esp, "<<4*sz<<"\n";
}

string char_to_int(string sym){
    if(sym[0]!='\'')return sym;
    if(sym[1] == '\\'){
        //cout<<"HERE\n";
        string s = sym.substr(1,2);
        //cout<<s<<"\n";
        if(s == "\\0") return "0";
        // TODO
    } 
    int val = (int )sym[1];
    sym = to_string(val);
    return sym;
}


void assign_op(quad* instr){

    instr->arg1.first = char_to_int(instr->arg1.first);
    // x = 1
    if(instr->res.second->is_derefer){
        cout<<"I am here"<<endl;
        string res_mem = getReg(&instr->res, &empty_var, &instr->arg1, -1);
        string arg1_mem = getReg(&instr->arg1, &empty_var, &instr->res, -1);
        res_mem = "[ " + res_mem + " ]";

        if(instr->arg1.second->is_derefer){
            code_file<<"\tmov "<<arg1_mem <<", [ "<<arg1_mem<<" ]"<<"\n";
        }
        // cout<<"I am here 2 "<<endl;
        code_file<<"\tmov "<<res_mem<<", "<<arg1_mem<<"\n";
        //cout<<"\tmov "<<res_mem<<", "<<arg1_mem<<"\n";
        // cout<<"I am here 3 "<<endl;
    }
    else if(is_integer(instr->arg1.first)){
        // string reg = getReg(instr->res, qid("", NULL), qid("", NULL), instr->idx);
        string mem = get_mem_location(&instr->res, &instr->arg1, instr->idx, 1);
        code_file << "\tmov "<< mem << ", dword "<< stoi(instr->arg1.first) <<endl;
        //nstr->res.second->addr_descriptor.stack = 0;
    }
    else if(typeLookup(instr->res.second->type)){
        
        for(auto it: reg_desc){
            free_reg(it.first);
        }

        string reg = getTemporaryReg(&empty_var, instr->idx);
        int res_offset = instr->res.second->offset, temp_offset = instr->arg1.second->offset;
        int struct_size = getStructsize(instr->res.second->type);
        
        for(int i = 0; i<struct_size; i+=4){
            code_file<<"\tmov "<<reg<<", [ ebp - "<<temp_offset + 4 + i<<" ]\n";
            code_file<<"\tmov [ ebp - "<<res_offset + 4 + i<<" ], "<<reg<<"\n";
        }
    } 
    // x = y
    else{
        string reg = getReg(&instr->arg1, &instr->res, &empty_var, instr->idx);
        if(instr->arg1.second->is_derefer){
            code_file<<"\tmov "<<reg <<", [ "<<reg<<" ]"<<"\n";
            update_reg_desc(reg, &instr->res);        
        }
        else {
            // update_reg_desc(reg, &instr->res);        // since reg will still hold y's value, keep y in reg
            reg_desc[reg].insert(instr->res);
            string prev_reg = instr->res.second->addr_descriptor.reg;
            if(prev_reg != "") reg_desc[prev_reg].erase(instr->res);
            instr->res.second->addr_descriptor.reg = reg;
            cout<<"HERE !! "<<reg<<" "<<instr->res.first<<"\n";
        }
        
        if(instr->res.second->type[instr->res.second->type.length()-1] == '*'){
            pointed_by[addr_pointed_to[instr->arg1]] = 1;
        }

        if(pointed_by[instr->res.second->offset]){
            string reg_stored = instr->res.second->addr_descriptor.reg;
            instr->res.second->addr_descriptor.reg = "";
            reg_desc[reg_stored].erase(instr->res);
            string str = get_mem_location(&instr->res, &instr->arg1, instr->idx, 0);
            code_file<<"\tmov "<< str <<", "<<reg_stored<<"\n";
        }
        instr->res.second->addr_descriptor.stack = 0;
    }
}

void gen_func_label(quad* instr){
    string s = "";
    for(int i=5;i<instr->op.first.size(); i++){
        if(instr->op.first[i] == ' ')break;
        s += instr->op.first[i];
    }
    // string name = "";
    // // for(int i = 5; i<instr->op.first.length(); i++){
    // //     if(instr->op.first[i] == ' ') break;
    // //     name+=instr->op.first[i];
    // // }
    
    // curr_func = s;
    arg_size = 0;
    sym_entry* func_entry = lookup(s);
    for(auto it: *(func_entry->entry)){
        if(it.second->offset < 0){
            // cout<<it.second->offset<<" ";
            arg_size = max(arg_size, abs(it.second->offset));
        }
    }
    if(arg_size) arg_size+=4;
    else arg_size = 8;
    // cout<<"\n";


    code_file << s << " :\n";
    code_file << "\tpush ebp\n";
    code_file << "\tmov ebp, esp\n"; 
    code_file << "\tsub esp, "<<func_local_size(s)<<"\n";

    pointed_by.clear();
}


void lshift_op(quad* instr){    // <<
    exclude_this.insert("ecx");
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    
    if(instr->arg1.second->is_derefer) {
        string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
        code_file<<"\tmov "<<str <<", "<< reg1<<endl;
        code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
    }
    free_reg("ecx");
    string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);
    code_file << "\tmov " << "ecx" << ", " << mem2 <<"\n";
    mem2 = "cl";    
    code_file << "\tshl " << reg1 << ", " << mem2 <<"\n";
    exclude_this.clear();
    update_reg_desc(reg1, &instr->res);
}

void rshift_op(quad* instr){    // >>
    exclude_this.insert("ecx");
    string reg1 = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    
    if(instr->arg1.second->is_derefer) {
        string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
        code_file<<"\tmov "<<str <<", "<< reg1<<endl;
        code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
    }
    free_reg("ecx");
    string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);
    code_file << "\tmov " << "ecx" << ", " << mem2 <<"\n";
    mem2 = "cl";    
    code_file << "\tsar " << reg1 << ", " << mem2 <<"\n";
    exclude_this.clear();
    update_reg_desc(reg1, &instr->res);
}

void unary_op(quad* instr){
    // cout<<"vfvfewvdcdwc";
    string op = instr->op.first;
    string temp;
    // cout<<instr->arg1.second->addr_descriptor.reg;
   
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    temp =reg;

    string instruction = "";
    if(op[2] == 'P'){
        // TODO
        if(op == "++P")      instruction = "inc";
        else if(op == "--P") instruction = "dec";
        // string reg1 = getReg(&instr->res, &empty_var, &instr->arg1, instr->idx);
    
        // code_file<<"\tmov "<<reg1<<", "<<reg<<"\n";
        // code_file << "\t"<<instruction<<" "<<reg1 <<"\n";
        // string mem = get_mem_location(&instr->arg1, &instr->res, instr->idx, 0);
        // code_file << "\tmov " << mem << ", " <<  reg1<<"\n";
        // update_reg_desc(reg1, &instr->res);
        if(instr->arg1.second->is_derefer){
            string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            string reg1 = getTemporaryReg(&instr->arg1, instr->idx);

            reg = "[ " + reg + " ]";

            code_file<<"\tmov "<<reg1<<", "<<reg<<endl;
            code_file<<"\t"<<instruction<<" "<<reg1<<endl;
            code_file<<"\tmov "<<reg<<", "<<reg1<<endl;
            update_reg_desc(reg1, &instr->res);
        }
        else{
            string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            code_file<<"\t"<<instruction<<" "<<reg<<endl;
            free_reg(reg);
            update_reg_desc(reg, &instr->res);
        }
        
    }
    else if(op[2] == 'S'){
        //done for single lvl pointer
        if(op == "++S")      instruction = "inc";
        else if(op == "--S") instruction = "dec";
        // update_reg_desc(reg, &instr->res);
        // string reg1 = getReg(&instr->res, &empty_var, &instr->arg1, instr->idx);
        // // if(instr->arg1.second->is_derefer) code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
        // code_file<<"\tmov "<<reg1<<", "<<reg<<"\n";
        // string mem = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
        // code_file<<"\tmov "<< mem <<", "<<reg1<<"\n";
        // free_reg(reg1);
        // code_file << "\t"<<instruction<< " "<<reg1<<"\n";
        // code_file<<"\tmov "<<reg<<", "<<reg1<<"\n";
        if(instr->arg1.second->is_derefer){
            string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            string reg1 = getTemporaryReg(&instr->arg1, instr->idx);

            reg = "[ " + reg + " ]";
            code_file<<"\tmov "<<reg1<<", "<<reg<<endl;
            update_reg_desc(reg1, &instr->res);

            code_file<<"\t"<<instruction<<" "<<reg1<<endl;
            code_file<<"\tmov "<<reg<<", "<<reg1<<endl;
        }
        else{
            string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
            code_file<<"\tmov "<<reg1<<", "<<reg<<endl;
            update_reg_desc(reg1, &instr->res);

            code_file<<"\t"<<instruction<<" "<<reg<<endl;
            string str = get_mem_location(&instr->arg1, &empty_var,instr->idx,-1);
            code_file<<"\tmov "<<str<<", "<<reg<<"\n";
            // free_reg(reg);
        }
    }
    else if(op =="~" ) {
        instruction = "not";
        string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
        if(instr->arg1.second->is_derefer){
            // string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            // string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
            // string str = get_mem_location(&instr->arg1, &instr->res, instr->idx, -1);
            // code_file<<"\tmov "<<str<<", "<<reg<<"\n";
            reg = "[ " + reg + " ]";
        }

        code_file<<"\tmov "<<reg1<<", "<<reg<<"\n";
        code_file << "\t"<<instruction<< " "<<reg1<<"\n";        
        update_reg_desc(reg1, &instr->res);
    }
    else if(op == "unary-"){
        instruction = "neg";
        string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
        if(instr->arg1.second->is_derefer){
            // string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            // string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
            // string str = get_mem_location(&instr->arg1, &instr->res, instr->idx, -1);
            // code_file<<"\tmov "<<str<<", "<<reg<<"\n";
            reg = "[ " + reg + " ]";
        }
        code_file<<"\tmov "<<reg1<<", "<<reg<<"\n";
        code_file << "\t"<<instruction<< " "<<reg1<<"\n";        
        update_reg_desc(reg1, &instr->res);
    }
    else if(op == "unary+"){
        // instruction = "neg";
        // code_file << "\t"<<instruction<< " "<<reg <<"\n";   
        // string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
        // code_file<<"\tmov "<<reg1<<", "<<reg<<"\n";     
        // update_reg_desc(reg1, &instr->res);
        reg_desc[reg].insert(instr->res);
        instr->res.second->addr_descriptor.reg = reg;
    }
    else if(op == "!"){
        string l1 = get_label();
        string l2 = get_label();
        string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
        if(instr->arg1.second->is_derefer){
            // string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
            // string reg1 = getTemporaryReg(&instr->arg1, instr->idx);
            // string str = get_mem_location(&instr->arg1, &instr->res, instr->idx, -1);
            // code_file<<"\tmov "<<str<<", "<<reg<<"\n";
            reg = "[ " + reg + " ]";
        }
        code_file<<"\tmov "<<reg1<<", "<<reg<<"\n";
        code_file << "\tcmp "<<reg1<<", dword "<<0<<"\n";  //dword inserted
        code_file << "\tje "<<l1<<"\n";
        code_file << "\tmov "<<reg1<<", dword "<<0<<"\n";
        code_file << "\tjmp "<<l2<<"\n";
        code_file << l1 <<":\n";
        code_file << "\tmov "<<reg1<<", dword "<<1<<"\n";
        code_file << l2 <<":\n";
        update_reg_desc(reg1, &instr->res);
    }
}

void logic_and(quad *instr){
    
    if(is_integer(instr->arg1.first) && is_integer(instr->arg2.first)){
        int a = stoi(instr->arg1.first);
        int b = stoi(instr->arg2.first);
        string reg = get_mem_location(&instr->res, &empty_var, instr->idx, 1);
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
        if(instr->arg1.second->is_derefer){
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg<<endl;
            code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";
        }

        string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);
    
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
        string reg = get_mem_location(&instr->res, &empty_var, instr->idx, 1);
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
        if(instr->arg1.second->is_derefer){
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg<<endl;
            code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";
        }

        string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);

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
        if(op[0] == '^')      val = (stoi(instr->arg1.first) ^ stoi(instr->arg2.first));
        else if(op[0] == '&')  val = (stoi(instr->arg1.first) & stoi(instr->arg2.first));
        else if(op[0] == '|') val = (stoi(instr->arg1.first) | stoi(instr->arg2.first));
        string mem = get_mem_location(&instr->res, &empty_var, instr->idx, 1);
        code_file << "\tmov " << mem <<", " << "dword "<< val << "\n";
        return;
    }
    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    if(instr->arg1.second->is_derefer){
        string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
        code_file<<"\tmov "<<str <<", "<< reg<<endl;
        code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";
    }

    string instruction = "";
    if(op[0] == '^')      instruction = "xor";
    else if(op[0] == '&') instruction = "and";
    else if(op[0] == '|') instruction = "or";
    
    string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);
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
        string mem = get_mem_location(&instr->res, &empty_var, instr->idx, 1);
        code_file << "\tmov " << mem <<", " << "dword "<< val << "\n";
        return;
    }

    string reg = getReg(&instr->arg1, &empty_var, &instr->arg2, instr->idx);
    if(instr->arg1.second->is_derefer){
        string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
        code_file<<"\tmov "<<str <<", "<< reg<<endl;
        code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";
    }

    string jump_instruction = "";
    
    if(op == "==")      jump_instruction = "je";
    else if(op == "<")  jump_instruction = "jl";
    else if(op == "<=") jump_instruction = "jle";
    else if(op == ">")  jump_instruction = "jg";
    else if(op == ">=") jump_instruction = "jge";
    else if(op == "!=") jump_instruction = "jne";

    string mem2 = get_mem_location(&instr->arg2, &instr->arg1, instr->idx, 0);

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
    if(instr->arg1.first == "IF"){
        string reg = get_mem_location(&instr->arg2, &instr->arg1, id, 1);
        if(is_integer(instr->arg2.first)) reg = getReg(&instr->arg2, &empty_var, &empty_var, instr->idx);
        code_file << "\tcmp " << reg <<", " << "dword 0"<<"\n";
        code_file << "\tjne "<<leaders[id]<<"\n";
    }
    else{
        code_file << "\tjmp " << leaders[id] <<"\n";
    }
}

void pointer_op(quad* instr){

    if(is_integer(instr->arg1.first)){
            // Give error

        return;
    }
    if(instr->arg1.first[0] != '#'){
        string reg = instr->arg1.second->addr_descriptor.reg;
        if(reg!= ""){
            instr->arg1.second->addr_descriptor.reg = "";
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 0);;
            code_file<<"\tmov "<< str <<", "<<reg<<"\n";
            reg_desc[reg].erase(instr->arg1);
        }
    }

    if(instr->op.first == "unary&"){
        string reg = getReg(&instr->res, &empty_var, &instr->arg1, instr->idx);
        string mem = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 2);

        if(instr->arg1.second->is_derefer){
            //cout<<"YO WASS UP\n";
            code_file<<"\tmov "<<reg<<", "<<mem<<"\n";
        }
        else{
            if(reg_desc.find(mem) != reg_desc.end()) mem =  get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tlea "<<reg<<", "<<mem<<"\n";
        }
        pointed_by[instr->arg1.second->offset] = 0;
        addr_pointed_to[instr->res] = instr->arg1.second->offset;
        update_reg_desc(reg, &instr->res);
    }
    else{
        // unary* 
        string reg = getReg(&instr->res, &empty_var, &instr->arg1, instr->idx);
        
        if(instr->arg1.second->is_derefer){
            string mem = getReg(&instr->arg1, &empty_var, &instr->res, -1);     
            code_file<<"\tmov "<<reg<<", [ "<<mem<<" ]\n";
        }
        else {
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 0);
            code_file<<"\tmov "<<reg<<", "<< str <<"\n";
        }
        instr->res.second->is_derefer = 1;

        update_reg_desc(reg, &instr->res);
    }
}

void ptr_op(quad* instr){
    // struct_node -> b

    string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
    if(instr->arg1.second->is_derefer){
        string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
        code_file<<"\tmov "<<str <<", "<< reg<<endl;
        code_file<<"\tmov "<<reg<<", [ "<<reg<<" ]\n";
    }
    cout<<reg<<" "<<instr->arg2.second->offset<<"\n";
    code_file<<"\tadd "<<reg<<", "<<instr->arg2.second->offset<<"\n";

    if(!instr->arg2.second->isArray) instr->res.second->is_derefer = 1;
    update_reg_desc(reg, &instr->res);
}

void member_access(quad* instr){
    if(!instr->arg1.second->is_derefer){
        // cout<<"HERE\n";
        instr->res.second->offset = instr->arg1.second->offset - instr->arg2.second->offset - instr->arg2.second->size + instr->arg1.second->size;
        if(instr->arg2.second->isArray) {
            instr->res.second->offset += instr->arg2.second->size - 4;
        }
        pointed_by[instr->res.second->offset] = 1;
        instr->res.second->isArray = instr->arg2.second->isArray;
        // instr->res.second->array_dims = instr->arg2.second->array_dims;
        for(int i: instr->res.second->array_dims) {
            cout<<i<<"\n";
        }
        // cout<<instr-
        // cout<<instr->arg1.second->offset<<" "<<instr->arg2.second->offset<<" "<<instr->arg1.second->size<<"\n";
        // cout<<"offset "<<instr->res.second->offset<<"\n";
    }
    else{
        string reg = getReg(&instr->arg1, &instr->res, &instr->arg2, instr->idx);
        // cout<<reg<<" "<<instr->arg2.second->offset<<"\n";
        code_file<<"\tadd "<<reg<<", "<<instr->arg2.second->offset<<"\n";
        if(!instr->arg2.second->isArray) instr->res.second->is_derefer = 1;
        
        update_reg_desc(reg, &instr->res);
    }
}

void array_op(quad* instr){
        string reg = getReg(&instr->res, &empty_var, &instr->arg2, instr->idx);
        string mem, str;
        
        if(instr->arg1.second->isArray) {    //First index
            if(instr->arg1.second->addr_descriptor.reg != ""){
                string temp_reg = instr->arg1.second->addr_descriptor.reg;
                instr->arg1.second->addr_descriptor.reg = "";
                str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 0);
                code_file<<"\tmov "<< str <<", "<<temp_reg<<"\n"; 
            }
            // code_file<<";in if\n";    
            mem = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 0);
            code_file<<"\tlea "<<reg<<", "<<mem<<"\n";
        }
        else {
            // code_file<<";in else!!!\n";
            mem = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, 0);
            code_file<<"\tmov "<<reg<<", "<<mem<<"\n";
        }
        
        exclude_this.insert(reg);
        string reg1 = getReg(&instr->arg2, &empty_var, &instr->arg1, instr->idx);
       // free_reg(reg1);
        if(instr->arg2.second->is_derefer){
            string str = get_mem_location(&instr->arg1, &instr->arg2, instr->idx, -1);
            code_file<<"\tmov "<<str <<", "<< reg1<<endl;
            code_file<<"\tmov "<<reg1<<", [ "<<reg1<<" ]\n";
        }

        if(instr->arg1.second->type == "char*"){
            if(instr->arg1.second->array_dims.empty()) code_file<<"\timul "<<reg1<<", "<<1<<"\n";
            else code_file<<"\timul "<<reg1<<", "<<1*instr->arg1.second->array_dims[0]<<"\n";
        }
        else{
            if(instr->arg1.second->array_dims.empty()) code_file<<"\timul "<<reg1<<", "<<getSize(instr->res.second->type)<<"\n";
            else code_file<<"\timul "<<reg1<<", "<<getSize(instr->res.second->type)*instr->arg1.second->array_dims[0]<<"\n";
        }
       
        code_file<<"\tadd "<<reg<<", "<<reg1<<"\n";
        if(instr->arg1.second->array_dims.empty()) instr->res.second->is_derefer = 1;
        // cout<<instr->arg1.second->array_dims.empty() <<" "<<
        exclude_this.clear();
        reg_desc[reg1].erase(instr->arg2);
        instr->arg2.second->addr_descriptor.reg = "";
        
        
        update_reg_desc(reg, &instr->res);

}

void sizeof_op(quad* instr){
    string mem = get_mem_location(&instr->res, &empty_var, instr->idx, 0);
    // cout<<"HERE "<<instr->arg1.second->type<<" "<<getSize(instr->arg1.second->type)<<"\n";
    code_file<<"\tmov "<<mem<<", dword "<<instr->arg1.second->size<<"\n";
}

void genCode(){
    // Prints final code to be generated in asm file
    findBasicBlocks();
    initializeRegs();
    nextUse();
    vector<int> visited = findDeadCode();

    gen_data_section();
    starting_code();

    int index = 0;
    for (auto it=leaders.begin(); it != leaders.end(); it++){
       if(!visited[index++]){
        cout<<it->first<<endl;
        continue;
    }
        code_file << it->second <<":\n";
        auto it1 = it;
        it1++;
        if(it1 == leaders.end()) break;
        int ended = 0;
        int start = it->first;
        int end = it1->first;
        
        for(int idx=start; idx < end; idx++){
            quad instr = code[idx];
            if(instr.arg1.first != "") instr.arg1.first = char_to_int(instr.arg1.first);
            if(instr.arg2.first != "") instr.arg2.first = char_to_int(instr.arg2.first);
            
            code_file<<"\t;"<<instr.arg1.first<<" "<<instr.op.first<<" "<<instr.arg2.first<<" "<<instr.res.first<<"\n";
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
            else if(instr.op.first == "SIZEOF") sizeof_op(&instr);
        }
        if(!ended) end_basic_block();
    }
    for(auto it: stringlabels){
        it.second[0] = '\`', it.second[it.second.length()-1] = '\`';
        code_file<<"str"<<it.first<<": db "<<it.second<<", 0\n";
    }
}

void end_basic_block(){
    for(auto reg = reg_desc.begin();reg!=reg_desc.end();reg++){
        for(auto sym =reg->second.begin() ;sym!=reg->second.end(); sym++){
            if( is_integer(sym->first)) continue;
            sym->second->addr_descriptor.reg = "";
            qid tem = *sym;
            string str = get_mem_location(&tem, &empty_var, -1, -1); 
            cout<<reg->first<<endl;
            code_file<<"\tmov " << str <<", "<<reg->first<<"\n";
        }
        reg->second.clear();
    }
    //cout<<"Coming out of end_basic_block"<<endl;
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
    // cout<<reg<<endl;
    // cout<<sym->first<<endl;
    // cout<<typeid(*sym)<<endl;
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

// -1: only stack mem location required!!
// 0: otherwise
// 1: for instructions which require size
// 2: specifically requres address to be passed on further to some other variable
string get_mem_location(qid* sym, qid* sym2, int idx, int flag){
    if(is_integer(sym->first)){
        if(flag) return string("dword " + sym->first);
        else return sym->first;
    }

    if(sym->second->addr_descriptor.reg != "" && flag!=-1){
        if(!sym->second->is_derefer || flag == 2) return sym->second->addr_descriptor.reg;
        return "[ " + sym->second->addr_descriptor.reg + " ]";
    }
    

    if(sym->second->heap_mem == 0){
        //Symbol in stack
        int offset = sym->second->offset;
        int size = sym->second->size;
        string str;
        sym->second->addr_descriptor.stack = true;
        if(offset >= 0) str = string("[ ebp - " + to_string(offset + size) + " ]");
        else{
            offset=-offset;
            str = string("[ ebp + "+to_string(offset) +" ]");
        }
        if(sym->second->is_derefer && flag != -1){
            string reg = getTemporaryReg(sym2, idx);
            code_file<< "\tmov "<<reg<<", "<<str<<"\n";
            update_reg_desc(reg, sym);
            return "[ " + reg + " ]";
        }

        return str;
    }
    // Wont come here as of now
    sym->second->addr_descriptor.stack = false;
    sym->second->addr_descriptor.heap = true;
    return string("[ " + to_string(sym->second->heap_mem) + " ]");
}

string getTemporaryReg(qid* exclude_symbol, int idx){
    // freeDeadTemp(idx);
    string reg = "";
    int mn = 1000000;
    for (auto it : reg_desc){
        if( (exclude_symbol && it.second.find(*exclude_symbol) != it.second.end()) || exclude_this.find(it.first) != exclude_this.end()){
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
    return reg;
}

string getReg(qid* sym, qid* result, qid* sym2, int idx){
    // Allocates best register if available

    // Case 1
    string reg = "";
    if(sym->second->addr_descriptor.reg != "") {
        reg = sym->second->addr_descriptor.reg;
        // If Not temporary, update the value of reg. into memory
        // if(sym->first[0]!='#' && !(sym->second->addr_descriptor.stack || sym->second->addr_descriptor.heap)){
        //     cout<<"in getreg\n";
        //     sym->second->addr_descriptor.reg = "";
        //     string str = get_mem_location(sym, sym2, idx, 1); 
        //     code_file << "\tmov " << str << ", " << reg <<endl;
        // }
        vector<qid> temp;
        for(auto it: reg_desc[reg]){
            if(it.first[0]!='#' && !(it.second->addr_descriptor.stack || it.second->addr_descriptor.heap)){
                it.second->addr_descriptor.reg = "";
                string str = get_mem_location(&it, &empty_var, idx, -1); 
                it.second->addr_descriptor.stack = 1;
                code_file << "\tmov " << str << ", " << reg <<endl;
                temp.push_back(it);
            }
        }
        
        for(auto it: temp){
            reg_desc[reg].erase(it);
        }
        
        return reg;
    }

    reg = getTemporaryReg(sym2, idx);
    
    //check for char and set value in reg to 0
    // string tmp = char_to_int(sym->first);
    //if(sym->second->type == "char") code_file << "\txor "<< reg <<", "<<reg<<"\n";


    // code_file<<"; "<<sym->first<<" , Reg : "<<reg<<" "<<str<<endl;
    if(sym->first[0] == '\"'){
        stringlabels[string_counter] = sym->first;
        code_file<<"\tmov "<<reg<<", str"<<string_counter<<"\n";
        string_counter++;
    }
    else{
        string str = get_mem_location(sym, sym2, idx, -1);
        code_file << "\tmov " << reg << ", "<< str <<"\n";
        sym->second->addr_descriptor.reg = reg;
        reg_desc[reg].insert(*sym);
    }
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
            if(code[i].res.first != "" && code[i].res.first[0] == '#' && code[i].res.second && code[i].res.second->next_use == -1){
                code[i].res.second->next_use = i;
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


/////deadcode removal


void dfs(int curr, vector<int>&visited, vector<vector<int> >&adj_list){
    visited[curr]=1;
    for(auto h:adj_list[curr]){
        if(!visited[h]) dfs(h, visited, adj_list);
    }
}

vector<int> findDeadCode(){

    int n = leaders.size()+1;
    vector<int> visited(n, 0);
    vector<vector<int > > adj_list(n, vector<int>());

    int id = 0;
    unordered_map<int , int> get_leader;
    for(auto it:leaders){
        get_leader.insert(make_pair(it.first, id++));
    }
    id=0;
    for(auto it = leaders.begin(); it!=leaders.end(); ++it){
        int start = it->first;
        auto it1 = it;
        ++it1;
        if(it1 == leaders.end()) break;
        int last = it1->first - 1;

        if(code[last].op.first == "GOTO"){
            adj_list[id].push_back(get_leader[code[last].idx]);
            if(code[last].arg1.first == "IF") adj_list[id].push_back(get_leader[last+1]);
        }
        else{
            adj_list[id].push_back(get_leader[last+1]);
        }
        id++;
    }

    // for(int i=0; i<id; i++){
    //     cout<<i<<": ";
    //     for(auto h:adj_list[i]) cout<<"( "<<h<<")"<<", ";
    //     cout<<endl;
    // }

    dfs(0, visited, adj_list);

    for(int i=0; i<n; i++){
        cout<<visited[i]<<" ";
    }
    cout<<endl;
    return visited;
}


