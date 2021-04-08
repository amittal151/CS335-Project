#  **CS335 Compiler Design Project** 


## Description :
C compiler project prepared as a project in CS335A Course at IITK under supervision of Prof. Amey Karkare, Dept. of Computer Science and Engineering. 
As of now, Parser is implemented. 

## Milestone 1 : Scanner

    Steps to Build and Run Lexer (in Terminal):  
     1. cd src
     2. make
     3. cd ..
     4. ./bin/parser -l lex_dump_file_name ./tests/test1.c

You can also enter multiple files as arguments to the lexer. 

## Milestone 2: Parser

```
Steps to Build and Run Parser (in terminal):
1. cd src
2. make
3. cd ..
4. ./bin/parser ./tests/test1.c -o myAST.dot
5. dot -Tps myAST.dot -o image.ps   // to render the AST generated
```


## Milestone 3: Semantic Analysis
```
Steps to Build and Run Parser (in terminal):
1. cd src
2. make
3. cd ..
4. ./bin/parser ./tests/test1.c 
5. cat <func_name>.csv  // To view the Symbol table of Function <func_name>
```

The compiler dumps the symbol table of each function and struct defined. We also dump the Global Symbol Table in a file "#Global_Symbol_Table#.csv". If there is any error in the program, compiler gives an appropriate error and stops compilation.

The C Lex specification is taken from [Here](https://www.lysator.liu.se/c/ANSI-C-grammar-l.html)

The C Grammar specification is taken from [Here](https://www.lysator.liu.se/c/ANSI-C-grammar-y.html)
