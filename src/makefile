BIN=../bin

lexer:
	mkdir $(BIN)
	bison -d -o parser.cpp parser.y
	flex -o scanner.cpp lexer.l
	g++ -Wno-write-strings -o $(BIN)/lexer scanner.cpp parser.cpp  

clean:
	rm -r $(BIN)/
	rm ./*.cpp ./*.hpp
