# Verilog 语言笔记
---
## 基础知识
### 一、语言要素
1. 空白符：
   - 空格、制表符、换行符等。
   - 在编译和综合时，空白符被忽略。
2. 注释符：
   1. 单行注释：`//`，忽略从此处到行尾的内容
   2. 多行注释：`/* ... */`，忽略注释符之间的内容
3. 标识符：
    标识符被用来命名信号名、模块名、参数名等，可以是任意一组**字母、数字、$** 符号和 **_** 组合。标识符字母**区分**大小写，且第一个字符必须时字母或者下划线
4. 转义标识符
5. 关键字：
6. 数值：
	1. 基本逻辑数值状态：
        
        |  状态  |          含义          |
        | :----: | :--------------------: |
        |  `0`   |  低电平，逻辑0或“假”   |
        |  `1`   |  高电平，逻辑1或“真”   |
        | `x或X` | 不确定或未知的逻辑状态 |
        | `z或Z` |       高阻抗状态       |
	2. 整数及其表示：`<size>'<base_format><number>`

        |   数制   | 基数符号 |           合法表示符            |
        | :------: | :------: | :-----------------------------: |
        |  二进制  |  `b或B`  |     0、1、x、X、z、Z、?、_      |
        |  八进制  |  `o或O`  |      0-7、x、X、z、Z、?、_      |
        |  十进制  |  `d或D`  |      0-9、x、X、z、Z、?、_      |
        | 十六进制 |  `h或H`  | 0-9、a-f、A-F、x、X、z、Z、?、_ |
        ```verilog
        8'b10101010 // 二进制
        8'o52       // 八进制
        8'd42       // 十进制
        8'h2A       // 十六进制
        4'b1x_01    // 二进制1x01
        ```
    3. 实数及其表示：主要用于测试与仿真
        1. 十进制表示法
        2. 科学计数法
### 二、数据类型
1. 物理数据类型：连线型、寄存器型号和存储器型数据类型

    | 标记符 |    名称    |  类型  |
    | :----: | :--------: | :----: |
    | supply | 电源级驱动 |  驱动  |
    | strong |   强驱动   |  驱动  |
    |  pull  | 上拉级驱动 |  驱动  |
    | large  |   大容性   |  存储  |
    |  weak  |   弱驱动   |  驱动  |
    | medium |   中容性   |  存储  |
    | small  |   小容性   |  存储  |
    | highz  |   高阻抗   | 高阻抗 |
2. 连线型
    1. **常用类型**
        - ==`wire`：用于连接模块端口、模块内部信号或连续赋值语句的结果==
        - ==`tri`：三态连线型==
        - `wand`：弱与连线型
        - `wor`：弱或连线型
        - `trior`：三态或连线型
        - `triand`：三态与连线型 
    2. **连线型数据类型声明**
        `<net_declaration><drive_strength><range><delay>[list_of_variables]`
       - `<net_declaration>`：连线型数据类型声明
       - `<drive_strength>`：驱动强度
       - `<range>`：位宽范围
       - `<delay>`：延时 
       - `[list_of_variables]`：变量列表
3. 寄存器型
    `reg`：寄存器型数据类型，表示可以存储数据的变量。一般为无符号数，定义为有符号数会自动转化为补码形式
    ```verilog
    reg a; // 1位寄存器型数据，命名为a
    reg [3:0] b; // 4位寄存器型数据，命名为b
    reg[8:1] c, d, e; // 8位寄存器数据类型，命名分别为c、d、e
    ```
    一般为无符号数，定义为有符号数会自动转化为补码形式
    ```verilog
    reg signed [3:0] a; // 4位有符号寄存器型数据，命名为a
    a = -3; // 赋值为-3，自动转化为补码形式
    ```
    1. **连线型数据类型声明**
    `reg<range>[list_of_rigister_variables]`
    - `<range>`：位宽范围
    - `[list_of_rigister_variables]`：寄存器变量列表
4. 存储器型
    存储器型变量可以描述RAM型、ROM型存储器以及reg文件
    1. **存储器型数据类型声明**
    `reg<range1><name_of_register><range2>`
    `<range1>`和`<range2>`均为可选值，缺省时为1
    - `<range1>`：位宽范围
    - `<name_of_register>`：寄存器名称
    - `<range2>`：寄存器个数
    ```verilog
    reg [7:0] mem[0:15]; // 8位宽度，16个寄存器的存储器型数据
    reg [15:0] mem[0:31]; // 16位宽度，32个寄存器的存储器型数据
    ```
5. 抽象数据类型
   主要包括整型(`integer`)、实数型(`real`)、时间型(`time`)和参数型(`parameter`)
### 三、运算符和表达式
1. 算数运算符(+ - * / %)
   1. 结果位宽：由最长操作数决定
2. 关系操作符(>、<、>=、<=)
3. 相等关系操作符(等于`==`、不等于!=、全等于`===`、非全等`!==`)
   比较结果有三种，1，0和不定值x
4. 逻辑运算符(与&&、或||、非!)
   对于`a=4'b1001`，`b=4'b0000`，则`!a=1'b0`，`!b=1'b1`，`a&&b=0`，`a||b=1`
5. 按位操作符(取反~、按位与&、按位或|、按位异或^、按位同或~^)
6. 规约运算符(缩位运算符)
   与&、或|、异或^，以及相应非操作~&、~|、~^、^~
7. 移位运算符(左移运算符<<、右移运算符>>)
8. 条件运算符
   `<条件表达式>?<表达式1>:<表达式2>`
   条件表达式结果为真时，执行表达式1，结果为假时，执行表达式2.
9. 连接和复制运算符
    - 连接运算符{}
        {信号1某几位,信号2某几位,...,信号n某几位}
    - 复制运算符{{}}
        将一个表达式放入双重大括号中，复制因子放在第一层括号中
### 四、模块的基本概念
模块(module)是语言的基本单元，代表一个基本的功能块，描述某个设计的功能或结构以及与其他的模块通信的外部端口。
```verilog
module name(port_list); // 模块定义行
    端口定义
    ...
    数据类型说明
    ...
    逻辑功能描述
    ...
endmodule // 模块结束行
```
## 程序设计语句和描述方式
### 1. 数据流建模
#### (1)连续赋值语句
   - 连续赋值语句的目标类型主要是标量线网和向量线网两种
      1. 标量线网，如: wire a,b;
      2. 向量线网，如: wire [3:0]a,b;
   - 显式连续赋值语句
      - `assign #<delay><name>=Assignment expression;`
   - 隐式连续赋值语句
      - `<net_declaration><drive_strength><range>#<delay><name>=Assignment expression;`
   - 连续赋值语句注意事项
      - 连续赋值语句赋值目标只能为线网型
      - 只要右值发生变化，则表达式立即被运算，将结果赋给左值，没有任何的延迟
      - 连续赋值语句不能出现在过程块中
      - 多个连续赋值语句是并行的，与程序中位置顺序无关
      - 连续赋值语句中延时具有硬件电路惯性延时特性，任何小于其延时的信号变化脉冲都将被滤除，不会体现在输出端口上
### 2. 行为级建模
#### (1)概览
1. 过程语句
    - initial
    - always    **可综合**
2. 语句块
    - 串行语句块begin-end   **可综合**
    - 并行语句块fork-join
3. 赋值语句
    - 过程连续赋值assign
    - 过程赋值=、<= **可综合**
4. 条件语句
    - if-else   **可综合**
    - case, casez, casex    **可综合**
5. 循环语句
    - forever
    - repeat
#### (2)过程语句
1. initial
常在测试中使用，initial 语句从0时刻开始执行，只执行一次
```verilog
initial
    begin
        语句1;
        语句2;
        ...
        语句n;
    end
```
2. always
always 语句块从0时刻开始执行其中的行为语句；当执行完最后一条语句后，便再次执行语句块中的第一条语句，如此循环反复。
```verilog
always@(<敏感事件列表>)
    语句块
```

```verilog
@(a)    // 当信号a发生变化时
@(a or b)   // 当信号a或b发生变化时, 也可以写为@(a, b)
@(posedge clk)  // 信号clk上升沿触发
@(negedge clk)  // 信号clk下降沿触发
```
1. 注意问题
   - 过程语句中，被赋值信号必须为reg类型
   - 采用过程语句对组合电路进行描述时，需要将所有输入信号列入敏感信号列表
   - 采用过程语句对时序电路进行描述时，需要将时间信号和部分输入信号列入敏感信号列表

#### (3)语句块
1. begin-end
串行语句块，语句按顺序执行，延迟时间为相对延迟时间，相对于前一条语句执行结束进行计算，常用于电路设计
2. fork-join
并行语句块，语句并行执行，延迟时间为绝对迟延，相对于零时刻进行计算，常用于测试

#### (4)赋值语句
1. =
   - b=a，阻塞型赋值语句，串行语句块中按先后顺序依次执行，在并行语句块中同时执行
   - 先计算等式右端表达式的值，并立刻将值赋给左端变量，与仿真时间无关
2. <=
   - b<=a，非阻塞型赋值语句，在串行语句块中非阻塞型赋值没有先后顺序之分，排在前面语句不会影响后面语句运行，各语句并行执行
   - 先计算等式右端表达式的值，等到延迟时间结束后将计算值赋给左端变量
3. assign
`assign <寄存器变量>=<赋值表达式>;`
`deassign <寄存器变量>;`
4. force
`force <寄存器变量>=<赋值表达式>;`
`release <寄存器变量>;`
force语句优先级高于assign
#### (5)条件分支语句
1. if条件语句
形式: 
```verilog
if(条件表达式)
    语句块1;
else
    语句块2;
```
if-else语句允许一个或多个if语句的嵌套使用，语法格式与C语言类似
2. case条件分支语句
```verilog
case(控制表达式)
    值1: 语句块1
    值2: 语句块2
    ...
    值n: 语句块n
    default: 语句块n+1
endcase
```
#### (6)循环语句
1. forever语句
表示永久循环，直到遇到系统任务`$finish`为止，格式为:
```verilog
forever 语句或语句块
```
2. repeat语句
表示执行固定次数循环，格式为:
```verilog
repeat(循环次数表达式)
    语句或语句块(循环体);
```
3. while语句
表示条件循环，条件表达式为真时才会重复执行循环体，否则不执行循环体
```verilog
while(条件表达式) 语句或语句块;
```
4. for语句
```verilog
for(循环变量赋初值; 循环结束条件; 循环变量增值) 语句块
```
#### (7)generate语句
generate 是 Verilog 用来在综合（elaboration）阶段自动生成硬件结构的语句。
特点：
   - 在综合前展开，而不是运行时执行
   - 用于生成 重复结构、可配置结构、参数化结构

1. generate循环结构

generate循环的语法与for循环语句的语法很相似。**但是在使用时必须先在genvar声明中声明循环中使用的索引变量名，然后才能使用它。** genvar声明的索引变量被用作整数用来判断generate循环。genvar声明可以是generate结构的内部或外部区域，并且相同的循环索引变量可以在多个generate循环中，只要这些环不嵌套。genvar只有在建模的时候才会出现，在仿真时就已经消失了。

在“展开”生成循环的每个实例中，将创建一个隐式localparam，其名称和类型与循环索引变量相同。它的值是“展开”循环的特定实例的“索引”。可以从RTL引用此localparam以控制生成的代码，甚至可以由分层引用来引用。

Verilog中generate循环中的generate块可以命名也可以不命名。如果已命名，则会创建一个generate块实例数组。如果未命名，则有些仿真工具会出现警告，因此，最好始终对它们进行命名。
语法：
```verilog
genvar i;
generate
    for (i = 0; i < N; i = i+1) begin : block_name
        // 硬件实现
    end
endgenerate
```
例如：
```verilog
module nbit_xor #(
    parameter SIZE = 16
) (
    input  [SIZE-1:0] a,
    b,
    output [SIZE-1:0] y
);
    genvar gv_i;
    generate
        for (gv_i = 0; gv_i < SIZE; gv_i = gv_i + 1) begin : sblka
            xor uxor (y[gv_i], a[gv_i], b[gv_i]);
        end
    endgenerate
endmodule
```
2. 条件if-generate构造

条件语句从很多的备选块中选择最多一个generate块，有可能是一个也不选择的。在建模中，**条件必须为常量表达式。**

条件if-generate不关心是否命名，并且可以不具有**begin / end**。当然，上述两个条件只能包含一项。它也会创建单独的范围和层次结构级别，这个和generate循环是一样的。由于最多选择一个代码块，因此在单个的if-generate中以相同的名称命名所有的备用代码块是合法的，而且这有助于保持对代码的分层引用。但是，不同的generate构造中必须具有不同的名称。

```verilog
generate
    if (WIDTH == 32) begin
        // 生成 32-bit 版本
    end else begin
        // 生成 16-bit 版本
    end
endgenerate
```
3. 条件case-generate构造

与if-generate类似，case-generate也可用于从几个块中有条件地选择一个代码块。它的用法类似于基本case语句，并且if-generate中的所有规则也适用于case-generate块。
```verilog
generate
    case (MODE)
        0: begin : M0
            // 结构 0
        end
        1: begin : M1
            // 结构 1
        end
    endcase
endgenerate
```
### 3. 结构化建模
**结构化建模不可嵌套在 always/initial 等过程语句中。**
#### (1)模块级建模
1. 模块调用
    `模块名 <参数列表> 实例名(端口列表);`
    多次调用时可以写为
    ```
    模块名  <参数列表> 实例名1(端口名列表1),
            <参数列表> 实例名2(端口名列表2),
            ...
            <参数列表> 实例名n(端口名列表n);
    ```
    对同一模块进行多次调用时，还可以采用阵列调用方式，其格式如下:
    ```
    <被调用模块名><实例阵列名>[阵列左边界:阵列有边界](<端口连接列表>);
    ```
    例如:
    ```verilog
    module AND(andout, ina, inb);
    input ina, inb;
    output andout;
    assign andout=ina&inb;
    endmodule

    module ex_arrey(out, a, b);
    input[15:0] a,b;
    output[15:0] out;
    wire[15:0] out;
    AND AND_ARREY[15:0](out, a, b);
    endmodule
    ```
2. 端口对应方式
    1. 位置对应
    2. 端口名对应方式
        通过信号名和调用信号对应，语法如下：
        `模块名 <参数列表> 实例名(.端口名1(信号名1), .端口名2(信号名2), ...， .端口名n(信号名n));`
    3. 模块参数值
        1. 使用带有参数的模块实例语句修改参数值
        ```verilog
        module para1(C,D);
            parameter a=1;
            parameter b=1;
            ...
        endmodule

        module para2;
            ...
            para1 #(4,3) U1(C1,D1);
            //语句1
            para1 #(.b(6),.a(5)) U2(C2,D2);
            //语句2
            ...
        endmodule
        ``` 
        2. 使用定义参数语句(**defparam语句**)修改参数值
        ```verilog
        defparam    参数名1=参数值1,
                    参数名2=参数值2,
                    ...
                    参数值n=参数名n;
        ```
#### (2)门级建模
#### (3)开关级建模
1. mos开关
2. 双向开关

## 仿真测试与Testbench
### 1. 测试程序设计基础
#### (1)基本格式与要求
```verilog
module仿真模块名: // 无端口列表
数据类型说明
// 其中激励信号定义为reg型
// 显示信号定义为wire型
integer
parameter

待测试模块调用

激励向量定义
(always、initial过程块;
function, task结构等;
if-else, for, case, while, repeat, disable等控制语句
)
显示格式定义
($monitor, $time, $display等)

endmodule
```
1. testbench代码不需要可综合
2. 行为级描述效率较高
3. 掌握结构化、程式化描述方式

#### (2)仿真效率
1. 减小层次结构
2. 减少门级代码使用
3. 仿真精度越高，效率越低
    - ``` `timescale 仿真时间单位/时间精度;```
4. 进程越少，效率越高
5. 减少仿真器输出显示

#### (3)仿真相关的系统任务
1. `$display`和`$write`
    语法格式如下
    ```verilog
    $display("<format_specifiers>",<signal1, signal2,..., signaln>);
    $write("<format_specifiers>",<signal1, signal2,..., signaln>);
    ```
    "<format_specifiers>"称为"格式控制"，与C语言类似
    <signal1, signal2,..., signaln>称为"信号输出列表"
    `$display`自动在输出后换行
    `$write`输出特定信息时不自动换行

2. `$monitor`和`$strobe`
    1. `$monitor`语法格式
        ```verilog
        $monitor("<format_specifiers>",<signal1, signal2,..., signaln>);
        ```
        当参数列表中任意一个信号变化时打印结果
    2. `$strobe`语法格式
        ```verilog
        $strobe(<functions_or_signals>);
        $strobe("<string_and/or_variables>", <functions_or_signals>);
        ```
        在所有时间处理完后，以十进制格式输出一行格式化文本

3. `$time`和`$realtime`
    `$time`以64位整型返回仿真时间，而`$realtime`以实数类型返回仿真时间
    1. 系统函数`$time`
        ```verilog
        `timescale 1ns/1ns;
        module time_tb;
            reg ts;
            parameter delay = 2;
            initial begin
                #delay ts = 1;
                #delay ts = 0;
                #delay ts = 1;
                #delay ts = 0;
            end
            $initial
                $monitor($time,,"ts=%b", ts);
        endmodule
        ```

4. `$finish`和`$stop`
    `$finish`表示结束仿真，而`$stop`表示暂停仿真

5. `$random`语句
    语法格式如下
    `$random % b;`，其中b>0，它给出范围在(-b+1):(b-1)中的随机数。

#### (4)信号时间赋值语句
1. 时间延迟
    `#<延迟时间>行为语句;`
    `#<延迟时间>;`

   1. 串行延迟控制
    `begin-end`语句，相对上一时刻延迟时间

   2. 并行延迟控制
    `fork-join`语句，相对零时刻延迟时间

   3. 阻塞延迟控制
    ```verilog
    initial
    begin
        a = 0;
        a = #5 1;
        a = #10 0;
        a = #15 1;
    end
    ```

   4. 非阻塞延迟控制
    ```verilog
    initial
    begin
        a <= 0;
        a <= #5 1;
        a <= #10 0;
        a <= #15 1;
    end
    ```

2. 边沿触发时间控制
   语法格式如下，共有四种形式
   ```verilog
   @(<事件表达式>) 行为语句;
   @(<事件表达式>);
   @(<事件表达式1> or <事件表达式2> or ... or<事件表达式n>) 行为语句;
   @(<事件表达式1> or <事件表达式2> or ... or<事件表达式n>);
   ```
   1. 事件表达式
    共有三种表达方式
    ```verilog
    <信号名>
    posedge <信号名>
    negedge <信号名>
    ```

3. 电平敏感事件控制
    语法格式如下
    ```verilog
    wait(条件表达式) 行为语句;
    wait(条件表达式);
    ```

### 2. 任务和函数
#### (1)任务
##### 1. 基本语法
```verilog
task<任务名>;
端口和类型声明
局部变量声明
    begin
    语句1;
    语句2;
    ...
    语句n;
    end
endtask
```
##### 2. 任务调用
```verilog
<任务名> (端口1, 端口2, ..., 端口n);
```
==任务写在模块内部，只能调用当前模块内部的任务，无法调用其他模块内部任务==

#### (2)函数
在 Verilog 中，函数（function）是一种可以避免重复代码编写的结构，它允许将行为级设计提取出来并在多个地方调用。函数只能在模块内部定义和使用，且作用范围限于该模块。

函数的特点包括：
- 不含有任何延迟、时序或时序控制逻辑。
- 至少有一个输入变量。
- 只有一个返回值，且没有输出。
- 不含有非阻塞赋值语句。
- 函数可以调用其他函数，但不能调用任务（task）。
##### 1. 函数的定义
```verilog
function <返回值类型或位宽><函数名>;
<输入参量与类型说明>
<局部变量说明>
begin
    语句1;
    语句2;
    ...
    语句n;
end
endfunction
```
<返回值类型或位宽>为可选项，有以下三种选择
   1. "[msb:lsb]": 返回类型为多位寄存器变量
   2. "integer": 返回类型为整数型变量
   3. "real": 返回类型为实数型变量

具体实例如下
```verilog
function[3:0] out0;
input[7:0] x;
reg[3:0] count;
integer i;
begin
    count = 0;
    for(i = 0; i <= 7; i = i + 1)
        if(x[i] == 1'b0) count = count + 1;
    out0 = count;
end
endfunction
```

##### 2. 函数的调用
```verilog
<函数名> (<输入表达式1>, <输入表达式2>, ..., <输入表达式n>);
```
具体实例如下
```verilog
module endian_rvs #(parameter N = 4) (
   input wire en, // enable control
   input wire [N-1:0] a,
   output wire [N-1:0] b
);
   reg [N-1:0] b_temp;
   always @(*) begin
       if (en) begin
           b_temp = data_rvs(a);
       end else begin
           b_temp = 0;
       end
   end
   assign b = b_temp;
   // function entity
   function [N-1:0] data_rvs;
       input wire [N-1:0] data_in;
       parameter MASK = 32'h3;
       integer k;
       begin
           for(k=0; k<N; k=k+1) begin
               data_rvs[N-k-1] = data_in[k];
           end
       end
   endfunction
endmodule
```
1. 函数调用不能作为单一语句存在，只能作为一个操作数出现在调用语句内
2. 函数调用既能出现在过程块中，也能出现在assign连续赋值语句中
3. 函数定义中声明的所有局部寄存器均是静态的，在函数多个调用之间保持他们的值

### 3. 典型测试向量设计
#### (1)变量初始化
##### 1. initial初始化
通过initial语句进行初始化。initial语句只执行1次，0时刻被执行直到过程结束，专门用于对输入信号进行初始化和产生特定波形。==initial语句中变量必须位reg类型。==
##### 2. 定义变量时初始化
`reg [3:0] a = 4'b0000;`

#### (2)数据信号测试向量的产生
initial语句适合不规则序列产生，对于具有规律的序列，使用always产生

#### (3)时钟信号测试向量的产生
#### (4)总线信号测试向量的产生

### 4. 用户自定义元件模型UDP
#### (1) UDP的定义与调用
通过UDP，可以把一块组合逻辑电路或时序逻辑电路封装在一个UDP内，并把这个UDP作为一个基本门元件来使用。需要注意的是，UDP不能综合，只能用于仿真。

UDP定义格式如下：

```verilog
primitive<元件名称> (<输出端口名>, <输入端口名1>, <输入端口名2>,..., <输入端口名n>);
    输出端口类型声明(output);
    输入端口类型声明(input);
    输出端口寄存器变量说明(reg);
    元件初始状态说明(initial);
    table
        <table表项1>;
        <table表项2>;
        ...
        <table表项n>;
    endtable
endprimitive
```

与模块相比，UDP具有以下特点：
1. 输出端口只能有一个，且必须位于端口列表第一项。只有输出端口能定义为reg类型。
2. UDP的输入端可有多个，一般时序电路的输入端口最多9个，组合电路输入端口可多至10个。
3. 所有端口变量的位宽必须是1bit
4. 在table表项中，只能出现0、1、x这三种状态，z将被认为是x状态。
5. UDP的调用与模块调用类似，但是只能通过位置映射

### 5. 基本门级元件和模块的延时建模
#### (1) 门级延时建模
门级延时分类：
1. 上升延时: 0, x, z->1
2. 下降延时: 1, x, z->0
3. 到不定态的延时: 0, 1, z->x
4. 截止延时: 0, 1, x->z

#### (2) 门级延时基本延时表达式
门级延时基本表达形式下，“delay”内可以包含0-3个延时值。

|  延时值  | 无延时 | 1延时(d) | 2延时(d1, d2) | 3延时(dA, dB, dC) |
| :------: | :----: | :------: | :-----------: | :---------------: |
|   Rise   |   0    |    d     |      d1       |        dA         |
|   Fall   |   0    |    d     |      d2       |        dB         |
|   To_x   |   0    |    d     |  min(d1, d2)  |  min(dA, dB, dC)  |
| Turn_off |   0    |    d     |  min(d1, d2)  |        dC         |


#### (3) 门级延时最小、典型、最大延时表达形式
在该形式下，门级延时量中的每一项将由“最小延时”、“典型延时”和“最大延时”三个值表示，语法格式如下：
```verilog
# (d_min:d_type:d_max)
```
采用“最小、典型、最大”延时表达形式时，“delay”内可以包含1-3个延时值，使用 `,` 相隔。

### 6. 模块延时建模
#### (1) 延时说明块Specify Block
在模块输入和输出引脚之间的延迟称为模块路径延迟，在关键字specify和endspecify之间给路径延迟赋值，关键之之间的语句组成specify块。

Specify块包括下列操作语句：
1. 定义川谷模块所有路径延迟
2. 在电路中设置时序检查
3. 定义specparam常量

specify示例如下：
```verilog
module M(out, a, b, c, d);
    input a, b, c, d;
    output out;
    wire e, f;
    assign out = (a & b) | (c & d); // 逻辑功能
    specify // 包含specify块
        (a => out) = 9;
        (b => out) = 9;
        (c => out) = 11;
        (d => out) = 11;
    endspecify
endmodule
```
#### (2) 路径延迟描述方式
##### 1. 并行连接
每条路径延迟语句都有一个源域或一个目标域。上例路径延迟语句中，a、b、c和d在源域位置，而out时目标域。
在specify块中，使用符号 `=>` 说明并行连接，语法如下：
```verilog
(<source_field>=><destination_field>) = <delay_value>;
```
其中 `<delay_value>` 可以包含1-3个延时量，也可采用“最小、典型、最大”延时表示形式。在延时量由多个值组成的情况下，应在延时量外加上一对括号。

##### 2. 全连接
在specify块中，使用符号 `*>` 表示全连接，语法如下：
```verilog
(<source_field>*><destination_field>) = <delay_time>;
```
全连接中，源域中的每一位与目标域中的每一位相连接。**如果源和目标是向量，则不必位数相同。**

使用全连接，则上例可以改写为：
```verilog
module M(out, a, b, c, d);
    input a, b, c, d;
    output out;
    wire e, f;
    assign out = (a & b) | (c & d); // 逻辑功能
    specify
        (a, b *> out) = 9;
        (c, d *> out) = 11;
    endspecify
endmodule
```

##### 3. specparam声明
specparam用来定义specify块中的参数，语句格式类似parameter。但需要注意以下不同：
1. specparam语句只能在specify块中出现，而parameter语句则不能在specify块中出现。
2. 由specparam语句定义的参数只能是延时参数，而parameter语句定义的参数可以是任何数据类型的常数参数。
3. 由specparam语句定义的延时参数只能在specify块内使用，而parameter语句定义的参数可以在模块任意位置使用。

### 7. 预编译处理语句
#### (1) 宏定义
语法如下：
```verilog
`define <macro_name> <Text>
```

#### (2) 文件包含处理
语法如下：
```verilog
`include "文件名"
```

#### (3) 仿真时间标度
语法如下：
```verilog
`timescale <时间单位>/<时间精度>
```
