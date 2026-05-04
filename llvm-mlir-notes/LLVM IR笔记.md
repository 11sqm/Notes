# LLVM IR 笔记
---
## 一、LLVM 架构简介
### 1. LLVM是什么
LLVM通过将语言源代码编译成LLVM中间代码 (LLVM IR)，然后由LLVM后端对中间代码进行优化，并且编译到相应平台的二进制程序。

### 2. LLVM架构
#### (1) 前端语法分析
以C语言编译器Clang为例。对于最简单的C程序 `test.c`：
```C
int main() {
    return 0;
}
```

首先，前端编译器会将C语言代码进行预处理、语法分析、语义分析，将源代码转换为内存中有意义的数据。

通过指令，可以输出生成的抽象语法树 (AST)。
```bash
clang -Xclang -ast-dump -fsyntax-only test.c
```
其AST如下所示：
```AST
TranslationUnitDecl 0x104c5c08 <<invalid sloc>> <invalid sloc>
|-TypedefDecl 0x104c6430 <<invalid sloc>> <invalid sloc> implicit __int128_t '__int128'
| `-BuiltinType 0x104c61d0 '__int128'
|-TypedefDecl 0x104c64a0 <<invalid sloc>> <invalid sloc> implicit __uint128_t 'unsigned __int128'
| `-BuiltinType 0x104c61f0 'unsigned __int128'
|-TypedefDecl 0x104c67a8 <<invalid sloc>> <invalid sloc> implicit __NSConstantString 'struct __NSConstantString_tag'
| `-RecordType 0x104c6580 'struct __NSConstantString_tag'
|   `-Record 0x104c64f8 '__NSConstantString_tag'
|-TypedefDecl 0x104c6840 <<invalid sloc>> <invalid sloc> implicit __builtin_ms_va_list 'char *'
| `-PointerType 0x104c6800 'char *'
|   `-BuiltinType 0x104c5cb0 'char'
|-TypedefDecl 0x104c6b38 <<invalid sloc>> <invalid sloc> implicit __builtin_va_list 'struct __va_list_tag[1]'
| `-ConstantArrayType 0x104c6ae0 'struct __va_list_tag[1]' 1 
|   `-RecordType 0x104c6920 'struct __va_list_tag'
|     `-Record 0x104c6898 '__va_list_tag'
`-FunctionDecl 0x1051c820 <test.c:1:1, line:3:1> line:1:5 main 'int ()'
  `-CompoundStmt 0x1051c938 <col:12, line:3:1>
    `-ReturnStmt 0x1051c928 <line:2:5, col:12>
      `-IntegerLiteral 0x1051c908 <col:12> 'int' 0
```

其中，最后四行为源代码AST。可以很方便地看出，经过Clang前端的预处理、语法分析、语义分析，我们的代码被分析成一个函数，其函数体是一个复合语句，这个复合语句包含一个返回语句，返回语句中使用了一个整型字面量 `0`。

#### (2) 前端生成中间代码
根据内存中的抽象语法树AST生成LLVM IR中间代码，进而交给LLVM后端处理。

通过以下指令，可以生成 `test.ll` 文件。
```bash
clang -S -emit-llvm test.c
```

其中 `test.ll` 文件如下所示：
```llvm
; ModuleID = 'test.c'
source_filename = "test.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  ret i32 0
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 1}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
```
对于整个 `.ll` 文件，其核心为以下内容：
```llvm
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  ret i32 0
}
```

#### (3) LLVM后端优化IR
LLVM后端读取IR后，会通过 `opt` 组件对IR进行优化。它会根据输入的LLVM IR和相应的优化等级，进行相应的优化，并输出对应的LLVM IR。

可以通过
```bash
opt test.ll -S --O3
```
对相应的代码进行优化，也可以直接用
```bash
clang -S -emit-llvm -O3 test.c
```
进行优化，其中核心部分优化后如下所示：
```llvm
; Function Attrs: mustprogress nofree norecurse nosync nounwind readnone uwtable willreturn
define dso_local i32 @main() local_unnamed_addr #0 {
  ret i32 0
}
```

值得注意的是，实际上，上述的这个优化只能通过 `clang -S -emit-llvm -O3 test.c` 生成；如果对我们之前生成的 `test.ll` 使用 `opt test.ll -S --O3`，是不会有变化的。这是因为在Clang的D28404这个修改中，默认给所有 `O0` 优化级别的函数增加 `optnone` 属性，会导致函数不会被优化。如果要使 `opt test.ll -S --O3` 正确运行，我们生成 `test.ll` 时需要使用以下指令生成：
```bash
clang -cc1 -disable-O0-optnone -S -emit-llvm test.c
```

#### (4) LLVM后端生成汇编代码
LLVM后端通过 `llc` 组件由LLVM IR生成汇编代码，指令如下所示：
```bash
llc test.ll
```
生成 `test.s`：
```s
	.text
	.file	"test.c"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:
	xorl	%eax, %eax
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.ident	"Ubuntu clang version 14.0.0-1ubuntu1.1"
	.section	".note.GNU-stack","",@progbits
```

最后通过调用操作系统自带汇编器、链接器，最终生成可执行程序。

## 二、LLVM IR基本框架
### 1. 基本概念
对于LLVM IR，最基本程序为
```llvm
; main.ll
define i32 @main() {
    ret i32 0
}
```
其可视为最简单的C语言代码：
```C
int main() {
    return 0;
}
```

#### (1) 注释
`; main.ll` 为注释，在LLVM IR中，注释以 `;` 开头并延伸到行尾。

#### (2) 主程序
```llvm
define i32 @main() {
    ret i32 0
}
```
该部分为主程序，是程序执行的入口点。在 `@main()` 之后的，就是函数的函数体，`ret i32 0` 代表C语言中的 `return 0;`。

#### (3) 目标平台和数据布局
##### [1] 目标平台
在使用clang编译LLVM IR代码时，会出现警告：
```
warning: overriding the module target triple with x86_64-unknown-linux-gnu [-Woverride-module]
```

这是由于不同指令集CPU，其能够运行的二进制指令不同，对应汇编代码也不同。而对于不同的操作系统来说，其支持的可执行程序格式是不同的。不同格式之间，其所包含的元信息不同，二进制指令的组织形式也有可能不同。

即使CPU和操作系统一致，也有可能会有一些其他的原因导致生成的二进制程序不一致。因此，往往还会加上「vendor」这一项。所以笼统而言，CPU–vendor–OS这三者决定了一个平台，只要这三者一致，则生成的二进制程序往往就可以确定了。这三者就被称为一个 **「目标三元组」（Target Triple）**。

对于AMD64架构下的Linux，想要消除编译时的警告，可以使用
```bash
clang main.ll -o main --mtriple "x86_64-unknown-linux-gnu"
```
或者在 `main.ll` 中加入一行
```llvm
target triple = "x86_64-unknown-linux-gnu"
```

另外，在Apple Silicon Mac上的目标三元组为 `aarch64-apple-darwin`，在常见PC机上的目标三元组就是 `x86_64-pc-windows-msvc`。

##### [2] 目标数据布局
高级语言中常见数据类型，在底层看来，大小端序、数据长度、数据对齐都应当考虑在内，因此在声明目标平台时，往往默认了对应数据布局。

LLVM也支持手动定制数据布局。具体参考[Data Layout](https://llvm.org/docs/LangRef.html#data-layout)。

## 三、数据表示
一个简化后的内存模型如下图所示：
```
+------------------------------+
|          stack_data          |
|         heap_pointer         |  <------------- stack
+------------------------------+
|                              |
|                              |  <------------- available memory space
|                              |
+------------------------------+
| data pointed by heap_pointer |  <------------- heap
+------------------------------|
|          global_data         |  <------------- .data section
+------------------------------+
```

由于堆中的数据无法独立存在，一定会有一个位于其他位置的引用，且除了内存之外，还有寄存器存储数据，因此，在程序中可以用来表示的数据一共分为三类：
- 寄存器中的数据
- 栈上的数据
- 数据区的数据

### (1) 数据区与符号表
数据区里的数据，其最大特点时，能够给整个程序的任何一个地方使用。同时，数据区数据是占静态二进制可执行程序体积的。所以，我们应该只将需要全程序使用的变量放在数据区中，且这类全局静态变量应该越少越好。

由于LLVM是面向多平台的，所以应当考虑数据处理。一般来说，大多数平台的可执行程序格式中包含 `.data` 分区，用来存储这类数据，但除此以外，每个平台还有专门的更加细致的分区，比如说，Linux的ELF格式中就有 `.rodata` 来存储只读的数据。因此，LLVM的策略是，让我们尽可能细致地定义一个全局变量，比如说注明其是否只读等，然后依据各个平台，如果平台的可执行程序格式支持相应的特性，就可以进行优化。

一般来说，在LLVM IR中定义一个存储在数据区的全局变量，其格式为：
```llvm
@global_variable = global i32 0
```
这个语句定义了一个 `i32` 类型的全局变量 `@global_variable`，并且将其初始化为 `0`。

如果是只读的全局变量，也就是常量，我们可以用 `constant` 来代替 `global`：
```llvm
@global_constant = constant i32 0
```
这个语句定义了一个 `i32` 类型的全局变量 `@global_constant`，并且将其初始化为 `0`。

#### [1] 符号与符号表
在LLVM IR中，所有全局变量名称都要以 `@` 开头。

直接定义的全局变量，其名称会出现在符号表中。

由于在传统C语言编译模型中，编译器将每个 `.c` 文件（也成为编译单元）编译为一个 `.o` 目标文件，然后链接器将 `.o` 文件链接为一个可执行文件。这么做的好处是，如果一个项目特别大，编译器就不需要将所有 `.c` 文件都读入内存中一起处理，而是可以并行地、高效地单独处理每个 `.c` 文件。对于动态链接的程序而言，在程序加载、运行时，也会由动态链接器将相应的库动态链接进程序之中。

换言之，编译器生成的结果需要给链接器和动态链接器进行处理，这一过程需要使用**符号表**。

在上述的过程中，编译器的输入是一个编译单元，而输出是一个目标文件。那么在源码中，一个 `.c` 文件中调用了别的文件中实现的函数，编译器无法知道函数位置，因此编译器选择的策略是将这个函数的调用用一个符号代替，在将来链接以及动态链接的时候，再进行替换。

整体符号处理过程为：
1. 编译器对源代码按文件进行编译。对于每个文件中的未知函数，记录其符号；对于这个文件中实现的函数，暴露其符号。
2. 链接器收集所有的目标文件，对于每个文件而言，将其记录下的未知函数的符号，与其他文件中暴露出的符号相对比，如果找到匹配的，就成功地解析（resolve）了符号。
3. 部分符号在程序加载、执行时，由动态链接库给出。动态链接器将在这些阶段，进行类似的符号解析。

一个符号本身就是一个字符串。由于一个项目中往往会链接多个第三方库，可能存在想暴露的函数名与其他第三方库函数名重复。因此在LLVM IR中，引入链接与可见性概念，并提供对应修饰符控制相应行为。

#### [2] 链接类型
对于链接类型，常用有默认 `external`、`private` 和 `internal`。

默认情况下，即不加任何说明，则默认将全局变量名字放在符号表中，该函数可以在链接时呗其他编译单元看到。

使用 `private`，则代表中国变量名字不会出现在符号表中。
```llvm
@global_variable = private global i32 0
```

使用 `internal` 则表示变量以局部符号身份出现（全局变量的局部符号，可以理解成C中的 `static` 关键词）。
```llvm
@global_variable = internal global i32 0
```
将其编译成可执行程序，并用 `nm` 查看，可以看到这个符号。但是，在链接过程中，这个符号并不会参与符号解析。

#### [3] 可见性
可见性在实际使用中则比较少，主要分为三种 `default`, `hidden` 和 `protected`，这里主要的区别在于符号能否被重载。`default` 的符号可以被重载，而 `protected` 的符号则不可以；此外，`hidden` 则不将变量放在动态符号表中，因此其它的模块不可以直接引用这个符号。

#### [4] 可抢占性
在我们日常看到的LLVM IR中，会经常见到 `dso_local` 这样的修饰符，在LLVM中被称作运行时抢占性修饰符。简单来说，`dso_local` 保证了程序按照预想运行。

举例如下：
```C
// interposition1.c
void f(void) {
    printf("From interposition1\n");
}

// interposition2.c
void f(void) {
    printf("From interposition2\n");
}

void g(void) {
    f();
}

// interposition-main.c
void g();

int main() {
    g();
    return 0;
}
```

将 `interposition1.c` 和 `interposition2.c` 分别编译为动态链接库，并给 `main` 来调用。最简单的做法是：
```bash
clang -fPIC interposition1.c --shared -o libinterposition1.so
clang -fPIC interposition2.c --shared -o libinterposition2.so
clang -L. -linterposition1 -linterposition2 interposition-main.c -o interposition
```

预期程序输出结果为“From interposition2”，但是实际输出为“From interposition1”。

在 `interposition2` 汇编代码中，可以发现 `g` 函数实现为
```s
g:
    pushq    %rbp
    movq     %rsp, %rbp
    callq    f@PLT
    popq     %rbp
    retq
```
虽然 `f` 在同一个文件内，但是默认去PLT表寻找实现。但更改编译方式，在编译 `libinterposition2.so` 时增加`-fno-semantic-interposition` ，即如下指令：
```bash
clang -fPIC interposition1.c --shared -o libinterposition1.so
clang -fPIC -fno-semantic-interposition interposition2.c --shared -o libinterposition2.so
clang -L. -linterposition1 -linterposition2 interposition-main.c -o interposition
```
则与预期输出一致，观察生成的 `interposition2.ll`，可以发现：
```llvm
define dso_local void @f() {
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str)
  ret void
}

define dso_local void @g() {
  call void @f()
  ret void
}
```
`f` 和 `g` 都有了 `dso_local` 的修饰符。`dso_local` 就是告诉链接器，这个不许抢占，在生成动态链接库的时直接调用，而不是去PLT表寻找。

当使用 `clang -O3` 等级别进行优化编译时，则无需添加 `-fno-semantic-interposition` 就可以达成一样的效果。

#### [5] C示例
对于以下代码定义的变量与函数：
```C
int a;
extern int b;
static int c;
void d(void);
void e(void) {}
static void f(void) {}
```
以上为在C语言中最常见符号形式，通过Clang编译为LLVM IR，其结果为：
```llvm
@a = dso_local global i32 0, align 4
@b = external global i32, align 4
@c = internal global i32 0, align 4

declare void @d()

define dso_local void @e() {
  ret void
}

define internal void @f() {
  ret void
}
```
不难发现，在默认编译选项下：
- C语言中的 `static`，也就是当前文件中定义，别的文件不可以用的，都会加上 `internal` 修饰符。
- C语言中的 `extern`，也就是别的文件中定义的，全局变量会加上 `external` 修饰符，函数会使用 `declare`。
C语言中定义的，可以给别的文件使用的全局变量或函数，不会加上链接类型修饰符，并且会加上 `dso_local` 保证不会被抢占。