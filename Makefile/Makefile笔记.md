# Makefile笔记
---
## 一、简介
笔记参考教程为[文档](https://seisman.github.io/how-to-write-makefile/overview.html)中内容，仅仅是作为学习记录，未经允许不得转载。
## 二、Makefile基础
### 1. Makefile规则
```Makefile
target ...: prerequisites ...
    recipe
    ...
    ...
```
1. **target**
    可以是一个object file（目标文件），也可以是一个可执行文件，还可以是一个标签（label）。
2. **prerequisites**
    生成该target所依赖的文件和/或target。
3. **recipe**
    该target要执行的命令（任意的shell命令）。

这是一个文件的依赖关系，==**prerequisites中如果有一个以上的文件比target文件要新的话，recipe所定义的命令就会被执行。**==

### 2. 示例解读
#### 2.1 示例
以下示例为3个头文件与8个C文件构成
```Makefile
edit : main.o kbd.o command.o display.o \
        insert.o search.o files.o utils.o
    cc -o edit main.o kbd.o command.o display.o \
        insert.o search.o files.o utils.o

main.o : main.c defs.h
    cc -c main.c
kbd.o : kbd.c defs.h command.h
    cc -c kbd.c
command.o : command.c defs.h command.h
    cc -c command.c
display.o : display.c defs.h buffer.h
    cc -c display.c
insert.o : insert.c defs.h buffer.h
    cc -c insert.c
search.o : search.c defs.h buffer.h
    cc -c search.c
files.o : files.c defs.h buffer.h command.h
    cc -c files.c
utils.o : utils.c defs.h
    cc -c utils.c
clean :
    rm edit main.o kbd.o command.o display.o \
        insert.o search.o files.o utils.o
```
反斜杠(`\`)此处表示换行。生成可执行文件输入 `make` ，删除可执行文件和所有的中间目标文件输入 `make clean`。
>此处 `clean` 并非文件，仅仅作为一个动作名字，其冒号后什么也没有，那么，make就不会自动去找它的依赖性，也就不会自动执行其后所定义的命令。要执行其后的命令，就要在make命令后明显得指出这个label的名字。

**recipe一定要以 `Tab` 键开头.**

#### 2.2 工作流程
1. make会在当前目录下找名字叫“Makefile”或“makefile”的文件。

2. 如果找到，它会找文件中的第一个目标文件（target），在上面的例子中，他会找到“edit”这个文件，并把这个文件作为最终的目标文件。

3. 如果edit文件不存在，或是edit所依赖的后面的 `.o` 文件的文件修改时间要比 `edit` 这个文件新，那么，他就会执行后面所定义的命令来生成 `edit` 这个文件。

4. 如果 `edit` 所依赖的 `.o` 文件也不存在，那么make会在当前文件中找目标为`.o`文件的依赖性，如果找到则再根据那一个规则生成 `.o` 文件。

5. 当然，你的C文件和头文件是存在的啦，于是make会生成 `.o` 文件，然后再用 `.o` 文件生成make的终极任务，也就是可执行文件 `edit` 了。

### 3. 使用变量
Makefile中变量为一串字符串，可以类比为C语言中的宏。

由于示例中 `.o` 文件字符串多次重复且较为复杂不易维护，可以使用变量替代。具体如下：
```Makefile
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o
```
如果要使用该变量，则在makefile中以 `$(objects)` 方式使用。如果有新的 `.o` 文件加入，则修改 `objects` 变量即可。

### 4. 自动推导
GNU的make可以自动推导文件以及文件依赖关系后面的命令，于是我们就没必要去在每一个 `.o` 文件后都写上类似的命令，因为，我们的make会自动识别，并自己推导命令。

只要make看到一个 `.o` 文件，它就会自动的把 `.c` 文件加在依赖关系中，如果make找到一个 `whateve.o` ，那么 `whatever.c `就会是 `whateve.o` 的依赖文件。并且 `cc -c whatever.c` 也会被推导出来。所以示例的makefile可以写为：
```Makefile
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o
edit : $(objects)
    cc -o edit $(objects)

main.o : defs.h
kbd.o : defs.h command.h
command.o : defs.h command.h
display.o : defs.h buffer.h
insert.o : defs.h buffer.h
search.o : defs.h buffer.h
files.o : defs.h buffer.h command.h
utils.o : defs.h

.PHONY : clean
clean :
    rm edit $(objects)
```
这种方法就是make的“隐式规则”。上面文件内容中，`.PHONY` 表示 `clean` 是个伪目标文件。

### 5. 另一种风格
`make`指令可以自动推导，也可以实现 `.o` 文件和 `.h` 文件的依赖收拢。所以makefile可以写为
```Makefile
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o

edit : $(objects)
    cc -o edit $(objects)

$(objects) : defs.h
kbd.o command.o files.o : command.h
display.o insert.o search.o files.o : buffer.h

.PHONY : clean
clean : 
    rm edit $(objects)
```
这种风格能让我们的makefile变得很短，但我们的文件依赖关系就显得有点凌乱了。鱼和熊掌不可兼得。

### 6. 清空目录(clean)的“规则”
一般风格为：
```Makefile
clean :
    rm edit $(objects)
```
更为稳健做法为：
```Makefile
.PHONY : clean
clean :
    -rm edit $(objects)
```
前面说过，`.PHONY` 表示 `clean` 是一个“伪目标”。而在 `rm` 命令前面加了一个小减号的意思就是，也许某些文件出现问题，但不要管，继续做后面的事。当然，`clean` 的规则不要放在文件的开头，不然，这就会变成 `make` 的默认目标，相信谁也不愿意这样。不成文的规矩是—— `clean` 从来都是放在文件的最后”。

### 7. Makefile组成
1. 显式规则。显式规则说明了如何生成一个或多个目标文件。这是由Makefile的书写者明显指出要生成的文件、文件的依赖文件和生成的命令。
2. 隐式规则。由于我们的make有自动推导的功能，所以隐式规则可以让我们比较简略地书写Makefile，这是由make所支持的。
3. 变量的定义。在Makefile中我们要定义一系列的变量，变量一般都是字符串，这个有点像你C语言中的宏，当Makefile被执行时，其中的变量都会被扩展到相应的引用位置上。
4. 指令。其包括了三个部分，一个是在一个Makefile中引用另一个Makefile，就像C语言中的include一样；另一个是指根据某些情况指定Makefile中的有效部分，就像C语言中的预编译#if一样；还有就是定义一个多行的命令。有关这一部分的内容，我会在后续的部分中讲述。
5. 注释。Makefile中只有行注释，和UNIX的Shell脚本一样，其注释是用 `#` 字符，这个就像C/C++中的 `//` 一样。如果你要在你的Makefile中使用 `#` 字符，可以用反斜杠进行转义，如：`\#` 。

**最后，还值得一提的是，在Makefile中的命令，必须要以`Tab`键开始。**

### 8. 包含其他Makefile文件
类似C语言 `#include` 语法，Makefile可以使用 `include` 指令包含其他Makefile，语法如下：
```Makefile
include <filenames>...
```
`<filenames>`可以是当前操作系统Shell的文件模式（可以包含路径和通配符）。

在 `include` 前面可以有一些空字符，但是绝不能是 `Tab` 键开始。 `include` 和 `<filenames>` 可以用一个或多个空格隔开。举个例子，你有这样几个Makefile： `a.mk` 、 `b.mk` 、 `c.mk` ，还有一个文件叫 `foo.make` ，以及一个变量 `$(bar)` ，其包含了 `bish` 和 `bash` ，那么，下面的语句：
```Makefile
include foo.make *.mk $(bar)
```
等价于
```Makefile
include foo.make a.mk b.mk c.mk bish bash
```
make命令开始时，会找寻 `include` 所指出的其它Makefile，并把其内容安置在当前的位置。如果文件都没有指定绝对路径或是相对路径的话，make会在当前目录下首先寻找，如果当前目录下没有找到，那么，make还会在下面的几个目录下找：
1. 如果make执行时，有 `-I `或 `--include-dir` 参数，那么make就会在这个参数所指定的目录下去寻找。
2. 接下来按顺序寻找目录 `<prefix>/include` （一般是 `/usr/local/bin` ）、 `/usr/gnu/include` 、 `/usr/local/include` 、 `/usr/include` 。

环境变量 `.INCLUDE_DIRS` 包含当前 `make` 会寻找的目录列表。应当避免使用命令行参数 `-I` 来寻找以上这些默认目录，否则会使得 `make` “忘掉”所有已经设定的包含目录，包括默认目录。

如果有文件没有找到的话，make会生成一条警告信息，但不会马上出现致命错误。它会继续载入其它的文件，一旦完成makefile的读取，make会再重试这些没有找到，或是不能读取的文件，如果还是不行，make才会出现一条致命信息。如果你想让make不理那些无法读取的文件，而继续执行，你可以在include前加一个减号“-”。如：
```Makefile
-include <filenames>...
```
其表示，无论include过程中出现什么错误，都不要报错继续执行。如果要和其它版本 `make` 兼容，可以使用 `sinclude` 代替 `-include` 。

### 9. 环境变量MAKEFILES
如果当前环境中定义 `MAKEFILES` ，那么make会把这个变量中的值做一个类似于 `include` 的动作。这个变量中的值是其它的Makefile，用空格分隔。**从这个环境变量中引入的Makefile的“默认目标”(the default goal)不会起作用，如果环境变量中定义的文件发现错误，make也会不理。** 不建议使用这一环境变量，因为只要这个变量一被定义，那么当你使用make时，所有的Makefile都会受到它的影响。

### 10. make工作方式
1. 读入所有的Makefile。
2. 读入被include的其它Makefile。
3. 初始化文件中的变量。
4. 推导隐式规则，并分析所有规则。
5. 为所有的目标文件创建依赖关系链。
6. 根据依赖关系，决定哪些目标要重新生成。
7. 执行生成命令。

## 三、书写规则
规则包含两部分，一个是依赖关系，一个是生成目标的方法。

在Makefile中，规则的顺序是很重要的，因为，Makefile中只应该有一个最终目标，其它的目标都是被这个目标所连带出来的，所以一定要让make知道你的最终目标是什么。一般来说，定义在Makefile中的目标可能会有很多，但是第一条规则中的目标将被确立为最终的目标。如果第一条规则中的目标有很多个，那么，第一个目标会成为最终的目标。make所完成的也就是这个目标。

### 1. 规则语法
```Makefile
targets : prerequisites
    command
    ...
```
或
```Makefile
targets : prerequisites ; command
    command
    ...
```

1. targets：文件名，以空格分开，可以使用通配符。

2. command：命令行，如果其不与“target:prerequisites”在一行，那么，必须以 `Tab` 键开头，如果和prerequisites在一行，那么可以用分号做为分隔。

3. prerequisites：目标依赖文件，如果其中的某个文件要比目标文件要新，那么，目标就被认为是“过时的”，被认为是需要重生成的。

### 2. 通配符
`make`支持三个通配符：`*`，`?`和`~`。

`~` 在文件名中有较特殊用途，不爱事故当前用户的 `$HOME` 目录。而形如 `~a` 则表示用户a的宿主目录。在Windows或是MS-DOS下，用户没有宿主目录，波浪号所指的目录根据环境变量 `HOME` 而定。

`*` 会搜索文件系统来普配文件名，匹配任意字符数，如 `*.c` 表示所有后缀为c的文件。

 `?`则在在特定位置中匹配单个字母，如如 `?.c` 表示所有后缀为c且文件名仅含有单个字符的文件。
 
 如果文件名中有通配符，如 `*`，那么可以使用转义字符 `\` ，如 `\*` 来表示真是的 `*`字符。以下为几个例子：
```Makefile
clean :
    rm -f *.o
```

此外，通配符也可以用在规则中，下例中目标print依赖于所有的 `.c` 文件，其中的 `$?` 是一个自动化变量。
```Makefile
print : *.c
    lpr -p $?
    touch print
```

同理，通配符也可以用在变量中。**但在下面需要注意的是，由于类似C语言宏定义，`*.o` 并不会展开，变量objects的值就是 `*.o`。**
```Makefile
objects = *.o
```

**如果要让通配符展开，需要使用 `wildcard` 函数进行包裹。** 建议总是使用 `wildcard` 函数进行包裹。可以参考下面例子。
```Makefile
objects := $(wildcards *.o)
```

### 3. 文件搜寻
