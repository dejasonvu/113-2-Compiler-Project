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
./mycompiler < test.rs
```
就能得到對應的 Jasmin 指令檔（檔名為 Main.j）。  
如果想要進一步得到轉換後的 Java Bytecode 和執行程式，再輸入：
```sh
make Main.class
make run
```
便可完成。

在此使用以下的 μRust 程式碼為例子：
```sh
fn main() { // Your first μrust program
    println("Hello World!"); // println!("Hello World!"); in rust
    /* Hello 
    World */ /*
    */
}
```
轉換後的 Jasmin 指令檔內容為：
```sh
.source Main.j
.class public Main
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
.limit stack 100
.limit locals 100
        getstatic java/lang/System/out Ljava/io/PrintStream;
        ldc "Hello World!"
        invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V
        return
.end method
```
先後送入 Jasmin 和 JVM，得到的程式執行結果：（在此不展示其 Java Bytecode）
```sh
Hello World!
```
