# Syntax Analyzer（Parser）
該 Parser 為 μRust Compiler 的模組之一，主要負責將已切割的 Token 進行語法分析，並在過程中操作符號表。  
該模組由 Bison 實作。
## Introduction
- 將 Token 按照正確順序輸出（考量優先級和結合性）
- 在處理語法分析時，也會進行對應的語意動作
- 紀錄有回傳值的 Token 之屬性
- 針對出現的函數與變數，使用符號表將其資訊儲存
## Example
此資料夾有提供 Makefile，只要打上
```sh
make
```
即可完成編譯並取得 myparser。
由於 parser 會利用到 Token，因此使用時還是以 μRust 程式碼傳入給 myparser。
假設 test.rs 是你想處理的 μRust 程式碼，請輸入
```sh
./myparser < test.rs
```
就能得到按照順序輸出的 Token，以及符號表的操作過程。
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
> Create symbol table (scope level 0)
func: main
> Insert `main` (addr: -1) to scope level 0
> Create symbol table (scope level 1)
STRING_LIT "Hello World!"
PRINTLN str

> Dump symbol table (scope level: 1)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  

> Dump symbol table (scope level: 0)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  
0         main      -1        func      -1        1         (V)V      
Total lines: 6
```
