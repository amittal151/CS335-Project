BIN=../bin

lexer:
	bison -d -o parser.cpp parser.y
	flex -o scanner.cpp lexer.l
	g++ -Wno-write-strings -o $(BIN)/lexer scanner.cpp parser.cpp  

clean:
	rm  $(BIN)/* ./*.cpp ./*.hpp
