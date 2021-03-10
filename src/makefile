CC=g++ -w 
BIN=../bin
SRC=.

$(BIN)/parser: $(SRC)/parser.cpp $(SRC)/lexer.cpp $(SRC)/AST.cpp
	mkdir -p $(BIN)
	$(CC) -o $@ $^

$(SRC)/lexer.cpp: $(SRC)/lexer.l
	flex -o $@ $^
	
$(SRC)/parser.cpp: $(SRC)/parser.y
	bison -d -o $@ $^

clean:
	rm -rf $(BIN)/ 

allclean: clean
	rm -f $(SRC)/lexer.cpp $(SRC)/parser.hpp $(SRC)/parser.cpp
