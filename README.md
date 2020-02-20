# CS152 - Compilers at UCR Winter 2020

A lexical analyzer for MINI-L built with flex. For the Compilers course at UC Riverside.

## Part 1
### Instructions for use (Linux)
* `flex filename.lex` - creates a `lex.yy.c` file in the current directory
* `g++ -o lexer lex.yy.c -lfl` - Compiles lexical analyzer into the executable `lexer`
* If input is being read from file, execute with `./a.out name_of_file.txt`
* If input is being read from command line, execute with './a.out'

### Instructions for use (Mac)
* `flex filename.lex` - creates a `lex.yy.c` file in the current directory
* `gcc -std=c++11 lex.yy.c -ll` - Compiles lexical analyzer into the executable `lexer`
* If input is being read from file, execute with `./a.out name_of_file.txt`
* If input is being read from command line, execute with './a.out'

### Example Usage
To invoke lexical analyzer executable `lexer`, use
* `cat filename.min | lexer`

## Part2
### Instructions for use (Linux)
* `make` creates a `parser` executable in the current directory
* If input is read from file, execute with `cat | name_if_input_file.txt | parser`

### Instructions for use (Mac)
* `flex filename.lex` - creates a `lex.yy.c` file in the current directory
* `bison -v -d mini_l.y` compiles a `bison.c` file
* `gcc -std=c++11 -o parser mini_l.tab.c lex.yy.c -lfl` creates an executable `parser`
* If input is read from file, execute with `cat | name_if_input_file.txt | parser`
