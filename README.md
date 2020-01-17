# CS152 - Compilers at UCR Winter 2020

A lexical analyzer for MINI-L built with flex.

### Instructions for use (Linux)

* `flex filename.lex` - creates a `lex.yy.c` file in the current directory
* `gcc -o lexer lex.yy.c -lfl` - Compiles lexical analyzer into the executable `lexer`
* If input is being read from file, execute with `./a.out name_of_file.txt`
* If input is being read from command line, execute with './a.out'

### Instructions for use (Mac)
* `flex filename.lex` - creates a `lex.yy.c` file in the current directory
* `g++ -std=c++11 lex.yy.c -ll` - Compiles lexical analyzer into the executable `lexer`
* If input is being read from file, execute with `./a.out name_of_file.txt`
* If input is being read from command line, execute with './a.out'

### Example Usage
To invoke lexical analyzer executable `lexer`, use
* `cat filename.min | lexer`
