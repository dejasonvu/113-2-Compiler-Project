
/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h" //Extern variables that communicate with lex
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

    int cur_label = 0;
    int cur_ifelse_label = 0;
    int cur_while_label = 0;

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol(char *name, int mut, char *type, int lineno, int addr, char *func_sig);
    static SENTRY* lookup_symbol(char *name);
    static void dump_symbol();

    /* Global variables */
    bool g_has_error = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;
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
%left EQL '>' '<' NEQ
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
    : FUNC ID '(' ')' {
            insert_symbol($2, -1, "func", yylineno + 1, cur_address++, "(V)V");
            CODEGEN(".method public static %s([Ljava/lang/String;)V\n", $2);
            CODEGEN(".limit stack 100\n");
            CODEGEN(".limit locals 100\n");
            g_indent_cnt++;
        } Block {
            CODEGEN("return\n");
            g_indent_cnt--;
            CODEGEN(".end method\n");
        }
;

IdentifierDeclStmt
    : LET ID ':' Type '=' INT_LIT ';' {
            insert_symbol($2, 0, $4, yylineno + 1, cur_address, "-");
            CODEGEN("ldc %d\n", $6);
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
    | LET ID ':' Type '=' FLOAT_LIT ';' {
            insert_symbol($2, 0, $4, yylineno + 1, cur_address, "-");
            CODEGEN("ldc %f\n", $6);
            CODEGEN("fstore %d\n", cur_address);
            cur_address++;
        }
    | LET ID ':' '&' Type '=' '"' STRING_LIT '"' ';' {
            insert_symbol($2, 0, $5, yylineno + 1, cur_address, "-");
            CODEGEN("ldc \"%s\"\n", $8);
            CODEGEN("astore %d\n", cur_address);
            cur_address++;
        }
    | LET ID ':' Type '=' TRUE ';' {
            insert_symbol($2, 0, $4, yylineno + 1, cur_address, "-");
            CODEGEN("iconst_1\n");
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
    | LET ID ':' Type '=' FALSE ';' {
            insert_symbol($2, 0, $4, yylineno + 1, cur_address, "-");
            CODEGEN("iconst_0\n");
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
    | LET MUT ID ':' Type '=' INT_LIT ';' {
            insert_symbol($3, 1, $5, yylineno + 1, cur_address, "-");
            CODEGEN("ldc %d\n", $7);
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
    | LET MUT ID ':' Type '=' FLOAT_LIT ';' {
            insert_symbol($3, 1, $5, yylineno + 1, cur_address, "-");
            CODEGEN("ldc %f\n", $7);
            CODEGEN("fstore %d\n", cur_address);
            cur_address++;
        }
    | LET MUT ID ':' '&' Type '=' '"' '"' ';' {
            insert_symbol($3, 1, $6, yylineno + 1, cur_address, "-");
            CODEGEN("ldc \"\"\n");
            CODEGEN("astore %d\n", cur_address);
            cur_address++;
        }
    | LET MUT ID ':' Type '=' TRUE ';' {
            insert_symbol($3, 1, $5, yylineno + 1, cur_address, "-");
            CODEGEN("iconst_1\n");
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
    | LET MUT ID ':' Type '=' FALSE ';' {
            insert_symbol($3, 1, $5, yylineno + 1, cur_address, "-");
            CODEGEN("iconst_0\n");
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
    | LET MUT ID ':' Type ';' {
            insert_symbol($3, 1, $5, yylineno + 1, cur_address, "-");
            cur_address++;
        }
    | LET MUT ID '=' INT_LIT ';' {
            insert_symbol($3, 1, "i32", yylineno + 1, cur_address, "-");
            CODEGEN("ldc %d\n", $5);
            CODEGEN("istore %d\n", cur_address);
            cur_address++;
        }
;

Expression
    : Expression '+' Expression {
            $$ = $1;
            if(strcmp($1, "i32") == 0){
                CODEGEN("iadd\n");
            }else if(strcmp($1, "f32") == 0){
                CODEGEN("fadd\n");
            }
        }
    | Expression '-' Expression {
            $$ = $1;
            if(strcmp($1, "i32") == 0){
                CODEGEN("isub\n");
            }else if(strcmp($1, "f32") == 0){
                CODEGEN("fsub\n");
            }
        }
    | Expression '*' Expression {
            $$ = $1;
            if(strcmp($1, "i32") == 0){
                CODEGEN("imul\n");
            }else if(strcmp($1, "f32") == 0){
                CODEGEN("fmul\n");
            }
        }
    | Expression '/' Expression {
            $$ = $1;
            if(strcmp($1, "i32") == 0){
                CODEGEN("idiv\n");
            }else if(strcmp($1, "f32") == 0){
                CODEGEN("fdiv\n");
            }
        }
    | Expression '%' Expression {
            $$ = $1;
            CODEGEN("irem\n");
        }
    | Expression LSHIFT Expression {
            $$ = $1;
            if(strcmp($1, $3) != 0){
                printf("error:%d: invalid operation: LSHIFT (mismatched types %s and %s)\n", yylineno + 1, $1, $3);
            }
        }
    | Expression '>' Expression {
            $$ = "bool";
            if(strcmp($1, "i32") == 0){
                CODEGEN("if_icmpgt L_gtr_%d\n", cur_label);
                CODEGEN("iconst_0\n");
                CODEGEN("goto L_gtr_%d_end\n", cur_label);
                CODEGEN("L_gtr_%d:\n", cur_label);
                CODEGEN("iconst_1\n");
                CODEGEN("L_gtr_%d_end:\n", cur_label);
            }else if(strcmp($1, "f32") == 0){
                CODEGEN("fcmpg\n");
                CODEGEN("ifgt L_gtr_%d\n", cur_label);
                CODEGEN("iconst_0\n");
                CODEGEN("goto L_gtr_%d_end\n", cur_label);
                CODEGEN("L_gtr_%d:\n", cur_label);
                CODEGEN("iconst_1\n");
                CODEGEN("L_gtr_%d_end:\n", cur_label);
            }
            cur_label++;
        }
    | Expression '<' Expression {
            $$ = "bool";
            CODEGEN("if_icmplt L_lss_%d\n", cur_label);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_lss_%d_end\n", cur_label);
            CODEGEN("L_lss_%d:\n", cur_label);
            CODEGEN("iconst_1\n");
            CODEGEN("L_lss_%d_end:\n", cur_label);
            cur_label++;
        }
    | Expression EQL Expression {
            $$ = "bool";
            CODEGEN("if_icmpeq L_eql_%d\n", cur_label);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_eql_%d_end\n", cur_label);
            CODEGEN("L_eql_%d:\n", cur_label);
            CODEGEN("iconst_1\n");
            CODEGEN("L_eql_%d_end:\n", cur_label);
            cur_label++;
        }
    | Expression NEQ Expression {
            $$ = "bool";
            CODEGEN("if_icmpne L_neq_%d\n", cur_label);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_neq_%d_end\n", cur_label);
            CODEGEN("L_neq_%d:\n", cur_label);
            CODEGEN("iconst_1\n");
            CODEGEN("L_neq_%d_end:\n", cur_label);
            cur_label++;
        }
    | Expression LAND Expression {
            $$ = "bool";
            CODEGEN("imul\n");
            CODEGEN("ifgt L_land_%d\n", cur_label);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_land_%d_end\n", cur_label);
            CODEGEN("L_land_%d:\n", cur_label);
            CODEGEN("iconst_1\n");
            CODEGEN("L_land_%d_end:\n", cur_label);
            cur_label++;
        }
    | Expression LOR Expression {
            $$ = "bool";
            CODEGEN("iadd\n");
            CODEGEN("ifgt L_lor_%d\n", cur_label);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_lor_%d_end\n", cur_label);
            CODEGEN("L_lor_%d:\n", cur_label);
            CODEGEN("iconst_1\n");
            CODEGEN("L_lor_%d_end:\n", cur_label);
            cur_label++;
        }
    | Expression AS Type {
            if((strcmp($1, "i32") == 0) && (strcmp($3, "f32") == 0)){
                CODEGEN("i2f\n");
            }else if((strcmp($1, "f32") == 0) && (strcmp($3, "i32") == 0)){
                CODEGEN("f2i\n");
            }

            $$ = $3;
        }
    | '-' Expression %prec UMINUS {
            $$ = $2;
            if(strcmp($2, "i32") == 0){
                CODEGEN("ineg\n");
            }else if(strcmp($2, "f32") == 0){
                CODEGEN("fneg\n");
            }
        }
    | '!' Expression {
            $$ = "bool";
            CODEGEN("ifeq L_not_%d\n", cur_label);
            CODEGEN("iconst_0\n");
            CODEGEN("goto L_not_%d_end\n", cur_label);
            CODEGEN("L_not_%d:\n", cur_label);
            CODEGEN("iconst_1\n");
            CODEGEN("L_not_%d_end:\n", cur_label);
            cur_label++;
        }
    | '(' Expression ')' { $$ = $2; }
    | ID {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                $$ = symptr->type;
                if(strcmp(symptr->type, "i32") == 0){
                    CODEGEN("iload %d\n", symptr->addr);
                }else if(strcmp(symptr->type, "f32") == 0){
                    CODEGEN("fload %d\n", symptr->addr);
                }else if(strcmp(symptr->type, "bool") == 0){
                    CODEGEN("iload %d\n", symptr->addr);
                }else if(strcmp(symptr->type, "str") == 0){
                    CODEGEN("aload %d\n", symptr->addr);
                }
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
    | INT_LIT {
            $$ = "i32";
            CODEGEN("ldc %d\n", $1);
        }
    | FLOAT_LIT {
            $$ = "f32";
            CODEGEN("ldc %f\n", $1);
        }
    | TRUE {
            $$ = "bool";
            CODEGEN("iconst_1\n");
        }
    | FALSE {
            $$ = "bool";
            CODEGEN("iconst_0\n");
        }
;

AssignStmt
    : ID '=' Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                if(strcmp($3, "i32") == 0){
                    CODEGEN("istore %d\n", symptr->addr);
                }else if(strcmp($3, "f32") == 0){
                    CODEGEN("fstore %d\n", symptr->addr);
                }else if(strcmp($3, "bool") == 0){
                    CODEGEN("istore %d\n", symptr->addr);
                }
            }
        }
    | ID '=' '"' STRING_LIT '"' ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                CODEGEN("ldc \"%s\"\n", $4);
                CODEGEN("astore %d\n", symptr->addr);
            }
        }
    | ID ADD_ASSIGN Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                if(strcmp($3, "i32") == 0){
                    CODEGEN("iload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("iadd\n");
                    CODEGEN("istore %d\n", symptr->addr);
                }else if(strcmp($3, "f32") == 0){
                    CODEGEN("fload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("fadd\n");
                    CODEGEN("fstore %d\n", symptr->addr);
                }
            }
        }
    | ID SUB_ASSIGN Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                if(strcmp($3, "i32") == 0){
                    CODEGEN("iload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("isub\n");
                    CODEGEN("istore %d\n", symptr->addr);
                }else if(strcmp($3, "f32") == 0){
                    CODEGEN("fload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("fsub\n");
                    CODEGEN("fstore %d\n", symptr->addr);
                }
            }
        }
    | ID MUL_ASSIGN Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                if(strcmp($3, "i32") == 0){
                    CODEGEN("iload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("imul\n");
                    CODEGEN("istore %d\n", symptr->addr);
                }else if(strcmp($3, "f32") == 0){
                    CODEGEN("fload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("fmul\n");
                    CODEGEN("fstore %d\n", symptr->addr);
                }
            }
        }
    | ID DIV_ASSIGN Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                if(strcmp($3, "i32") == 0){
                    CODEGEN("iload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("idiv\n");
                    CODEGEN("istore %d\n", symptr->addr);
                }else if(strcmp($3, "f32") == 0){
                    CODEGEN("fload %d\n", symptr->addr);
                    CODEGEN("swap\n");
                    CODEGEN("fdiv\n");
                    CODEGEN("fstore %d\n", symptr->addr);
                }
            }
        }
    | ID REM_ASSIGN Expression ';' {
            SENTRY *symptr = lookup_symbol($1);
            if(symptr != NULL){
                CODEGEN("iload %d\n", symptr->addr);
                CODEGEN("swap\n");
                CODEGEN("irem\n");
                CODEGEN("istore %d\n", symptr->addr);
            }
        }
;

CondtionStmt
    : Expression {
            CODEGEN("ifeq L_if_%d_end\n", cur_ifelse_label);
        }
;

IfStmt
    : IF CondtionStmt Block {
            CODEGEN("L_if_%d_end:\n", cur_ifelse_label);
            cur_ifelse_label++;
        }
    | IF CondtionStmt Block ELSE {
            CODEGEN("goto L_else_%d_end\n", cur_ifelse_label);
            CODEGEN("L_if_%d_end:\n", cur_ifelse_label);
        } Block {
            CODEGEN("L_else_%d_end:\n", cur_ifelse_label);
            cur_ifelse_label++;
        }
;

WhileStmt
    : WHILE {
            CODEGEN("L_while_%d:\n", cur_while_label);
        } Expression {
            CODEGEN("ifeq L_while_%d_end\n", cur_while_label);
        } Block {
            CODEGEN("goto L_while_%d\n", cur_while_label);
            CODEGEN("L_while_%d_end:\n", cur_while_label);
            cur_while_label++;
        }
;

Block
    : '{' { create_symbol(); } StatementList '}' { dump_symbol(); }
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
    : PRINTLN '(' '"' STRING_LIT '"' ')' ';' {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("ldc \"%s\"\n", $4);
            CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }
    | PRINTLN '(' Expression ')' ';' {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            if(strcmp($3, "i32") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n");
            }else if(strcmp($3, "f32") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
            }else if(strcmp($3, "bool") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n");
            }else if(strcmp($3, "str") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
            }
        }
    | PRINT '(' Expression ')' ';' {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            if(strcmp($3, "i32") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/print(I)V\n");
            }else if(strcmp($3, "f32") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/print(F)V\n");
            }else if(strcmp($3, "bool") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/print(Z)V\n");
            }else if(strcmp($3, "str") == 0){
                CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
            }
        }
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
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "Main.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source Main.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");

    /* Symbol table init */
    // Add your code

    yylineno = 0;
    yyparse();

    /* Symbol table dump */
    // Add your code

    fclose(fout);
    fclose(yyin);

    if (g_has_error) {
        remove(bytecode_filename);
    }
    yylex_destroy();
    return 0;
}

static void create_symbol() {
    cur_scope++;
    symtab[cur_scope].num = 0;
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
    symtab[cur_scope].num = 0;
    cur_scope--;
}