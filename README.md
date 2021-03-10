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

The C Lex specification is taken from [Here](https://www.lysator.liu.se/c/ANSI-C-grammar-l.html)

The C Grammar specification is taken from [Here](https://www.lysator.liu.se/c/ANSI-C-grammar-y.html)
