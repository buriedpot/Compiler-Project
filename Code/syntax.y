%{
	#include <stdio.h>
	#include <stdlib.h>
	#include "syntaxtree.h"
	#include "scanner.h"
	#include "lex.yy.c"
	//#define YYDEBUG 1
	struct ASTNode *treeroot;
	extern int errorLexical;
	int errorSyntax = 0;
%}
%union {
	int type_int;
	float type_float;
	double type_double;
	struct ASTNode *type_node;
}

%token INT 
%token FLOAT 
%token ID SEMI TYPE STRUCT RETURN IF WHILE
%token COMMA OR AND RELOP PLUS MINUS STAR DIV LB RB LC RC DOT LP RP NOT ASSIGNOP ELSE

%type <type_node> Program ExtDefList ExtDef ExtDecList
%type <type_node> Specifier StructSpecifier OptTag Tag
%type <type_node> VarDec FunDec VarList ParamDec
%type <type_node> CompSt StmtList Stmt
%type <type_node> DefList Def DecList Dec
%type <type_node> Exp Args
%type <type_node> INT 
%type <type_node> FLOAT 
%type <type_node> ID SEMI TYPE STRUCT RETURN IF WHILE
%type <type_node> COMMA OR AND RELOP PLUS MINUS STAR DIV LB RB LC RC DOT LP RP NOT ASSIGNOP ELSE

/*Priority, fronter, lower; backer, higher*/
%left COMMA
%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT
%left LB RB LC RC DOT
%left LP RP
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
/*High-level Definitions*/
Program : ExtDefList { $$ = newNode(@$.first_line, Program, NULL); insertChildren($$, buildChildren(1, $1)); treeroot = $$; }
	;
ExtDefList : ExtDef ExtDefList { $$ = newNode(@$.first_line, ExtDefList, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| /*empty*/ { $$ = NULL; }
	;
ExtDef : Specifier ExtDecList SEMI { $$ = newNode(@$.first_line, ExtDef, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Specifier SEMI { $$ = newNode(@$.first_line, ExtDef, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| Specifier FunDec CompSt { $$ = newNode(@$.first_line, ExtDef, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| error SEMI { errorSyntax = 1; }
	;
ExtDecList : VarDec { $$ = newNode(@$.first_line, ExtDecList, NULL); insertChildren($$, buildChildren(1, $1));}
	| VarDec COMMA ExtDecList { $$ = newNode(@$.first_line, ExtDecList, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	;

/*Specifiers*/
Specifier : TYPE { $$ = newNode(@$.first_line, Specifier, NULL); insertChildren($$, buildChildren(1, $1));}
	| StructSpecifier { $$ = newNode(@$.first_line, Specifier, NULL); insertChildren($$, buildChildren(1, $1));}
	;
StructSpecifier : STRUCT OptTag LC DefList RC { $$ = newNode(@$.first_line, StructSpecifier, NULL); insertChildren($$, buildChildren(5, $1, $2, $3, $4, $5));}
	| STRUCT Tag { $$ = newNode(@$.first_line, StructSpecifier, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| error RC { errorSyntax = 1; }
	;
OptTag : ID { $$ = newNode(@$.first_line, OptTag, NULL); insertChildren($$, buildChildren(1, $1));}
	| /*empty*/ { $$ = NULL;}
	;
Tag : ID { $$ = newNode(@$.first_line, Tag, NULL); insertChildren($$, buildChildren(1, $1));}
	;

/*Declarators*/
VarDec : ID { $$ = newNode(@$.first_line, VarDec, NULL); insertChildren($$, buildChildren(1, $1));}
	| VarDec LB INT RB { $$ = newNode(@$.first_line, VarDec, NULL); insertChildren($$, buildChildren(4, $1, $2, $3, $4));}
	;
FunDec : ID LP VarList RP { $$ = newNode(@$.first_line, FunDec, NULL); insertChildren($$, buildChildren(4, $1, $2, $3, $4));}
	| ID LP RP { $$ = newNode(@$.first_line, FunDec, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| error RP { errorSyntax = 1; }
	;
VarList : ParamDec COMMA VarList { $$ = newNode(@$.first_line, VarList, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| ParamDec { $$ = newNode(@$.first_line, VarList, NULL); insertChildren($$, buildChildren(1, $1));}
	;
ParamDec : Specifier VarDec { $$ = newNode(@$.first_line, ParamDec, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	;


/*Statements*/
CompSt : LC DefList StmtList RC { $$ = newNode(@$.first_line, CompSt, NULL); insertChildren($$, buildChildren(4, $1, $2, $3, $4)); }
	| error RC { errorSyntax = 1; }
	;
StmtList : Stmt StmtList { $$ = newNode(@$.first_line, StmtList, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| /*empty*/ { $$ = NULL;}
	;
Stmt : Exp SEMI { $$ = newNode(@$.first_line, Stmt, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| CompSt { $$ = newNode(@$.first_line, Stmt, NULL); insertChildren($$, buildChildren(1, $1));}
	| RETURN Exp SEMI { $$ = newNode(@$.first_line, Stmt, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| IF LP Exp RP Stmt %prec LOWER_THAN_ELSE { $$ = newNode(@$.first_line, Stmt, NULL); insertChildren($$, buildChildren(5, $1, $2, $3, $4, $5));}
	| IF LP Exp RP Stmt ELSE Stmt { $$ = newNode(@$.first_line, Stmt, NULL); insertChildren($$, buildChildren(7, $1, $2, $3, $4, $5, $6, $7));}
	| WHILE LP Exp RP Stmt { $$ = newNode(@$.first_line, Stmt, NULL); insertChildren($$, buildChildren(5, $1, $2, $3, $4, $5));}
	| error SEMI { errorSyntax = 1; }
	;


/*Local Definitions*/
DefList : Def DefList { $$ = newNode(@$.first_line, DefList, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| /*empty*/ {$$ = NULL;}
	;
Def : Specifier DecList SEMI { $$ = newNode(@$.first_line, Def, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| error RC { errorSyntax = 1; }	
	;
DecList : Dec { $$ = newNode(@$.first_line, DecList, NULL); insertChildren($$, buildChildren(1, $1));}
	| Dec COMMA DecList { $$ = newNode(@$.first_line, DecList, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	;
Dec : VarDec { $$ = newNode(@$.first_line, Dec, NULL); insertChildren($$, buildChildren(1, $1));}
	| VarDec ASSIGNOP Exp { $$ = newNode(@$.first_line, Dec, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	;


/*Expressions*/
Exp : Exp ASSIGNOP Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp AND Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp OR Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp RELOP Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp PLUS Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp MINUS Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp STAR Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp DIV Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| LP Exp RP { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| MINUS Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| NOT Exp { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(2, $1, $2));}
	| ID LP Args RP { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(4, $1, $2, $3, $4));}
	| ID LP RP { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp LB Exp RB { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(4, $1, $2, $3, $4));}
	| Exp DOT ID { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| ID { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(1, $1));}
	| INT { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(1, $1));}
	| FLOAT { $$ = newNode(@$.first_line, Exp, NULL); insertChildren($$, buildChildren(1, $1));}
	| 
	;
Args : Exp COMMA Args { $$ = newNode(@$.first_line, Args, NULL); insertChildren($$, buildChildren(3, $1, $2, $3));}
	| Exp { $$ = newNode(@$.first_line, Args, NULL); insertChildren($$, buildChildren(1, $1));}
	;

%%
int main(int argc, char **argv) {
	if (argc == 1) {

	}
	else {
		FILE *fp = fopen(argv[1], "r");
		if (fp == NULL) {
			printf("File %s does not exist!\n", argv[1]);
			return -1;
		}
		yyrestart(fp);
	}
	//yydebug = 1;
	yyparse();
	printf("parse over\n");
	if (errorLexical || errorSyntax) return 0;
	preOrderShow(treeroot, 0);
	deleteTree(treeroot);
	return 0;
}
yyerror(char* msg) {
	fprintf(stderr, "Error type B at Line %d: %s\n", msg);
}
