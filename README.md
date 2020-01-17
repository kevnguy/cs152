# CS152 - Compilers at UCR Winter 2020

A lexical analyzer for MINI-L built with flex.

### Instructions for use

* `<flex filename.lex>` - creates a `<lex.yy.c>` file in the current directory
* `<gcc -o lexer lex.yy.c -lfl>` - Compiles lexical analyzer into the executable `<lexer>`

### Example Usage
To invoke lexical analyzer executable `<lexer>`, use
* `<cat filename.min | lexer>`
