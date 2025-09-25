# Lexical Analyzer（Scanner）
該 Scanner 為 μRust Compiler 的模組之一，
由 Flex 工具實作詞法分析，
主要負責將原始 μRust 程式碼切割成 Token。
## Introduction
- 從 μRust 程式碼取出 Token 並正確標示
- 支援統計原程式碼的總行數和註解行數
- 透過 State 的功能判斷是否為字串或是多行註解
## Example
此資料夾有提供 Makefile，只要打上：
```sh
make
```
即可完成編譯並取得 myscanner。  
假設 test.rs 是你想處理的 μRust 程式碼， 接著輸入：
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
其輸出結果：
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
