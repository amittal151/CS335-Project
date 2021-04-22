#include <bits/stdc++.h>
using namespace std;
#define ll long long
#define ull unsigned long long
#define sym_file 0
#define sym_function 1
#define sym_block 2

typedef struct sym_entry{
	string type;
	ull size;
	bool init;
	ull offset;
	map<string, sym_entry* > * entry;
}sym_entry;

typedef map<string, sym_entry* > sym_table; 
typedef map<string, pair< ull, sym_table* > > struct_sym_table;
typedef map<string, string> typ_table;

extern sym_table gst;
extern struct_sym_table struct_gst;
extern map<sym_table*, sym_table*> parent_table;
extern map<struct_sym_table*, struct_sym_table*> struct_parent_table;

// extern map<string, ull> struct_size;
extern map<string, vector<string> > func_arg;
extern ull struct_offset;
extern sym_table* curr_table; //store pointer of the current symbol table
extern sym_table* curr_structure;
extern struct_sym_table *curr_struct_table;
extern stack<ull> Goffset, Loffset, blockSz;
extern int avl;

//map<string, string> typ_table;
extern typ_table typ_gst;  
extern map<typ_table*, typ_table*> typ_parent_table;
extern typ_table* curr_typ;



void symTable_init();
sym_entry* createEntry(string type, ull size, bool init, ull offset);
void makeSymbolTable(string name, string f_type);
void removeFuncProto();
void updSymbolTable(string id);
sym_entry* lookup(string id);
sym_entry* currLookup(string id);
void insertKeywords();
string getType(string id);
void createStructTable();
int insertStructAttr(string attr, string type, ull size, bool init);
int printStructTable(string struct_name);
string StructAttrType(string struct_name, string id);
int typeLookup(string struct_name);
int currTypeLookup(string struct_name);
int findTypeAttr(string , string );
void createParamList();
void insertSymbol(sym_table& table, string id, string type, ull size, bool is_init, sym_table* ptr);
vector<string> getFuncArgs(string id);
void updInit(string id);
void updTableSize(string id);
void insertFuncArg(string &func, vector<string> &arg);
void printFuncArg();
void printSymbolTable(sym_table* table, string file_name);
ull getSize(string id);
string lookupType(string a);
void insertType(string a, string b);