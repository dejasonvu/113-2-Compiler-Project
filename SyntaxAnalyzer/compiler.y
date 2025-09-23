/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h"
    // #define YYDEBUG 1
    // int yydebug = 1;

    #define NSYMS 20
    #define NSCOS 5
    #define SLEN 15

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    typedef struct {
        char name[SLEN];
        int mut;
        char type[SLEN];
        int addr;
        int lineno;
        char func_sig[SLEN];
    } SENTRY;

    typedef struct {
        SENTRY entry[NSYMS];
        int num;
    } SCOPE;

    SCOPE symtab[NSCOS];
    int cur_scope = -1;
    int cur_address = -1;

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol(char *name, int mut, char *type, int lineno, int addr, char *func_sig);
    static SENTRY* lookup_symbol(char *name);
    static void dump_symbol();

    /* Global variables */
    bool HAS_ERROR = false;
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token LET MUT NEWLINE
%token INT FLOAT BOOL STR
%token TRUE FALSE
%token GEQ LEQ EQL NEQ LOR LAND
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%token IF ELSE FOR WHILE LOOP
%token PRINT PRINTLN
%token FUNC RETURN BREAK
%token ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type
%type <s_val> Expression

/* Yacc will start at this nonterminal */
%start Program

%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%left LOR
%left LAND
%left EQL '>' '<'
%left LSHIFT
%left '+' '-'
%left '*' '/' '%'
%left AS
%right UMINUS '!'

/* Grammar section */
%%

Program
    : { create_symbol(); } GlobalStatementList { dump_symbol(); }
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : FunctionDeclStmt
    | NEWLINE
;

FunctionDeclStmt
    : FUNC ID '(' ')' { printf("func: %s\n", $2); insert_symbol($2, -1, "func", yylineno + 1, cur_address++, "(V)V"); }  Block
;

ElmentList
    : Expression ',' ElmentList
    | Expression
;

IdentifierDeclStmt
    : LET ID ':' Type '=' INT_LIT ';' { printf("INT_LIT %d\n", $6); insert_symbol($2, 0, $4, yylineno + 1, cur_address++, "-");}
    | LET ID ':' Type '=' FLOAT_LIT ';' { printf("FLOAT_LIT %f\n", $6); insert_symbol($2, 0, $4, yylineno + 1, cur_address++, "-");}
    | LET ID ':' '&' Type '=' '"' STRING_LIT '"' ';' { printf("STRING_LIT \"%s\"\n", $8); insert_symbol($2, 0, $5, yylineno + 1, cur_address++, "-");}
    | LET ID ':' Type '=' TRUE ';' { printf("bool TRUE\n"); insert_symbol($2, 0, $4, yylineno + 1, cur_address++, "-"); }
    | LET ID ':' Type '=' FALSE ';' { printf("bool FALSE\n"); insert_symbol($2, 0, $4, yylineno + 1, cur_address++, "-"); }
    | LET ID ':' '[' Type ';' Expression ']' '=' '[' ElmentList ']' ';' { insert_symbol($2, 0, "array", yylineno + 1, cur_address++, "-"); }
    | LET MUT ID '=' INT_LIT ';' { printf("INT_LIT %d\n", $5); insert_symbol($3, 1, "i32", yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' Type ';' { insert_symbol($3, 1, $5, yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' Type '=' INT_LIT ';' { printf("INT_LIT %d\n", $7); insert_symbol($3, 1, $5, yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' Type '=' FLOAT_LIT ';' { printf("FLOAT_LIT %f\n", $7); insert_symbol($3, 1, $5, yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' '&' Type '=' '"' '"' ';' { printf("STRING_LIT \"\"\n"); insert_symbol($3, 1, $6, yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' '&' Type '=' '"' STRING_LIT '"' ';' { printf("STRING_LIT \"%s\"\n", $9); insert_symbol($3, 1, $6, yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' Type '=' TRUE ';' { printf("bool TRUE\n"); insert_symbol($3, 1, $5, yylineno + 1, cur_address++, "-"); }
    | LET MUT ID ':' Type '=' FALSE ';' { printf("bool FALSE\n"); insert_symbol($3, 1, $5, yylineno + 1, cur_address++, "-"); }
;

Expression
    : Expression '+' Expression { $$ = $1; printf("ADD\n"); }
    | Expression '-' Expression { $$ = $1; printf("SUB\n"); }
    | Expression '*' Expression { $$ = $1; printf("MUL\n"); }
    | Expression '/' Expression { $$ = $1; printf("DIV\n"); }
    | Expression '%' Expression { $$ = $1; printf("REM\n"); }
    | Expression LSHIFT Expression {
            $$ = $1;
            if(strcmp($1, $3) != 0){
                printf("error:%d: invalid operation: LSHIFT (mismatched types %s and %s)\n", yylineno + 1, $1, $3);
            }
            printf("LSHIFT\n");
        }
    | Expression '>' Expression {
            $$ = "bool";
            if(strcmp($1, $3) != 0){
                printf("error:%d: invalid operation: GTR (mismatched types %s and %s)\n", yylineno + 1, $1, $3);
            }
            printf("GTR\n");
        }
    | Expression '<' Expression { $$ = "bool"; printf("LSS\n"); }
    | Expression EQL Expression { $$ = "bool"; printf("EQL\n"); }
    | Expression LAND Expression { $$ = "bool"; printf("LAND\n"); }
    | Expression LOR Expression { $$ = "bool"; printf("LOR\n"); }
    | Expression AS Type {
            if((strcmp($1, "i32") == 0) && (strcmp($3, "f32") == 0)){
                printf("i2f\n");
            }else if((strcmp($1, "f32") == 0) && (strcmp($3, "i32") == 0)){
                printf("f2i\n");
            }

            $$ = $3;
        }
    | '-' Expression %prec UMINUS { $$ = $2; printf("NEG\n"); }
    | '!' Expression { $$ = "bool"; printf("NOT\n"); }
    | '(' Expression ')' { $$ = $2; }
    | ID {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                $$ = symptr->type;
                printf("IDENT (name=%s, address=%d)\n", $1, symptr->addr);
            }else{
                $$ = "undefined";
                printf("error:%d: undefined: %s\n", yylineno + 1, $1);
            }
        }
    | ID {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                printf("IDENT (name=%s, address=%d)\n", $1, symptr->addr);
            }
        } '[' Expression ']' {
            $$ = "array";
        }
    | INT_LIT { $$ = "i32"; printf("INT_LIT %d\n", $1); }
    | FLOAT_LIT { $$ = "f32"; printf("FLOAT_LIT %f\n", $1); }
    | TRUE { $$ = "bool"; printf("bool TRUE\n"); }
    | FALSE { $$ = "bool"; printf("bool FALSE\n"); }
;

Block
    : '{' { create_symbol(); } StatementList '}' { dump_symbol(); }
;

AssignStmt
    : ID '=' Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr == NULL){
                printf("error:%d: undefined: %s\n", yylineno + 1, $1);
            }else{
                printf("ASSIGN\n");

                if(symptr->mut == 0){
                    printf("error:%d: cannot borrow immutable borrowed content `%s` as mutable\n", yylineno + 1, $1);
                }
            }
        }
    | ID '=' '"' STRING_LIT '"' ';' { printf("STRING_LIT \"%s\"\n", $4); printf("ASSIGN\n"); }
    | ID ADD_ASSIGN Expression ';' { printf("ADD_ASSIGN\n"); }
    | ID SUB_ASSIGN Expression ';' { printf("SUB_ASSIGN\n"); }
    | ID MUL_ASSIGN Expression ';' { printf("MUL_ASSIGN\n"); }
    | ID DIV_ASSIGN Expression ';' { printf("DIV_ASSIGN\n"); }
    | ID REM_ASSIGN Expression ';' { printf("REM_ASSIGN\n"); }
;

IfStmt
    : IF Expression Block
    | IF Expression Block ELSE Block
;

WhileStmt
    : WHILE Expression Block
;

StatementList
    : StatementList Statement
    | Statement
;

Statement
    : Block
    | Expression ';'
    | IfStmt
    | WhileStmt
    | AssignStmt
    | PrintStmt
    | IdentifierDeclStmt
;

PrintStmt
    : PRINTLN '(' '"' STRING_LIT '"' ')' ';' { printf("STRING_LIT \"%s\"\n", $4); printf("PRINTLN str\n"); }
    | PRINTLN '(' Expression ')' ';' { printf("PRINTLN %s\n", $3); } 
    | PRINT '(' Expression ')' ';' { printf("PRINT %s\n", $3); }
;

Type
    : INT { $$ = "i32"; }
    | FLOAT { $$ = "f32"; }
    | BOOL { $$ = "bool"; }
    | STR { $$ = "str"; }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    cur_scope++;
    symtab[cur_scope].num = 0;

    printf("> Create symbol table (scope level %d)\n", cur_scope);
}

static void insert_symbol(char *name, int mut, char *type, int lineno, int addr, char *func_sig) {
    int e_idx = symtab[cur_scope].num;
    strcpy(symtab[cur_scope].entry[e_idx].name, name);
    symtab[cur_scope].entry[e_idx].mut = mut;
    strcpy(symtab[cur_scope].entry[e_idx].type, type);
    symtab[cur_scope].entry[e_idx].addr = addr;
    symtab[cur_scope].entry[e_idx].lineno = lineno;
    strcpy(symtab[cur_scope].entry[e_idx].func_sig, func_sig);

    symtab[cur_scope].num++;

    printf("> Insert `%s` (addr: %d) to scope level %d\n", name, addr, cur_scope);
}

static SENTRY* lookup_symbol(char *name) {
    for(int i = cur_scope; i >= 0; i--){
        for(int j = 0; j < symtab[i].num; j++){
            if(strcmp(symtab[i].entry[j].name, name) == 0){
                return &symtab[i].entry[j];
            }
        }
    }

    return NULL;
}

static void dump_symbol() {
    printf("\n> Dump symbol table (scope level: %d)\n", cur_scope);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",
        "Index", "Name", "Mut","Type", "Addr", "Lineno", "Func_sig");
    for(int i = 0; i < symtab[cur_scope].num; i++){
        printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
            i, symtab[cur_scope].entry[i].name, symtab[cur_scope].entry[i].mut, symtab[cur_scope].entry[i].type, symtab[cur_scope].entry[i].addr, symtab[cur_scope].entry[i].lineno, symtab[cur_scope].entry[i].func_sig);
    }

    symtab[cur_scope].num = 0;
    cur_scope--;
}
