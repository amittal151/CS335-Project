CC=g++ -w 
BIN=../bin
SRC=.

$(BIN)/lexer:	lexer.cpp 	parser.cpp	AST.cpp
	mkdir -p $(BIN)
	$(CC) -o $@ $^

lexer.cpp:	lexer.l parser.hpp
	flex -o lexer.cpp lexer.l
	
parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

clean:
	rm -rf $(BIN)/ 

allclean:	clean
	rm -f lexer.cpp parser.hpp parser.cpp
