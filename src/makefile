CC=g++ -w 
BIN=../bin
SRC=.

lexer:	lexer.cpp	
	if [ ! -d $(BIN) ]; then mkdir $(BIN); fi
	$(CC) -o $(BIN)/lexer $^

lexer.cpp:	lexer.l parser.hpp
	flex -o lexer.cpp lexer.l
	
parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

clean:
	rm -rf $(BIN)/ 

allclean:	clean
	rm -f ./*.cpp ./*.hpp
