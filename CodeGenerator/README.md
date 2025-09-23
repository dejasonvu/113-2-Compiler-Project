# Code Generator
該 Code Generator 為 μRust Compiler 的模組之一，主要負責產生與原始 μRust 程式碼相對應的 Jasmin 指令檔。  
該模組沿用 Parser 架構進一步實作。
## Introduction
- 取代原先 Parser 進行語法分析時順帶做的語意動作，並改輸出對應的 Jasmin 指令
- 生成的 Jasmin 指令檔能再透過 Jasmin 轉換成 Java Bytecode
- 再將其交給 JVM 得到程式執行結果
## Example
該資料夾有提供 Makefile，只要打上
```sh
make
```
即可完成編譯並取得 mycompiler。
假設 test.rs 是你想處理的 μRust 程式碼， 接著輸入
```sh
./myscanner < test.rs
```
就能得到切割完的 Token。
在此使用以下的 μRust 程式碼為例子：
```sh
fn main() { // Your first μrust program
    println("Hello World!"); // println!("Hello World!"); in rust
    /* Hello 
    World */ /*
    */
}
```
其輸出結果為：
```sh
fn               FUNC
main             IDENT
(                LPAREN
)                RPAREN
{                LBRACE
// Your first μrust program      COMMENT
                 NEWLINE
println          PRINTLN
(                LPAREN
"                QUOTA
Hello World!     STRING_LIT
"                QUOTA
)                RPAREN
;                SEMICOLON
// println!("Hello World!"); in rust     COMMENT
                 NEWLINE
/* Hello 
    World */             MUTI_LINE_COMMENT
/*
    */           MUTI_LINE_COMMENT
                 NEWLINE
}                RBRACE

Finish scanning,
total line: 6
comment line: 5
```
