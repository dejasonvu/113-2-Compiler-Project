# μRust Compiler Implementation
該課程專案為國立成功大學資訊工程學系113-2學期編譯系統之三次作業彙整，  
在 μRust Compiler 中，我分別實作以下模組：
- **[Lexical Analyzer](./LexicalAnalyzer)（Scanner）** - 負責將 μRust 程式碼切成 Token
- **[Syntax Analyzer](./SyntaxAnalyzer)（Parser）** - 針對已切割的 Token 做語法分析，同時進行符號表操作
- **[Code Generator](./CodeGenerator)** - 生成 Jasmin 指令串，後續可再轉成 Java Bytecode 並傳入 JVM 執行程式
  
各模組對應資料夾的 README.md 有提供更詳細的介紹（功能、用法及範例），歡迎參閱。  
在此建議先安裝 Flex 與 Bison。
