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
反斜杠(`\`)此处表示换行。生成可执行文件输入`make`，删除可执行文件和所有的中间目标文件输入`make clean`。
>此处`clean`并非文件，仅仅作为一个动作名字，其冒号后什么也没有，那么，make就不会自动去找它的依赖性，也就不会自动执行其后所定义的命令。要执行其后的命令，就要在make命令后明显得指出这个label的名字。

**recipe一定要以`TAB`键开头.**

#### 2.2 工作流程
1. make会在当前目录下找名字叫“Makefile”或“makefile”的文件。

2. 如果找到，它会找文件中的第一个目标文件（target），在上面的例子中，他会找到“edit”这个文件，并把这个文件作为最终的目标文件。

3. 如果edit文件不存在，或是edit所依赖的后面的`.o`文件的文件修改时间要比` edit `这个文件新，那么，他就会执行后面所定义的命令来生成` edit `这个文件。

4. 如果` edit `所依赖的`.o`文件也不存在，那么make会在当前文件中找目标为`.o`文件的依赖性，如果找到则再根据那一个规则生成`.o`文件。

5. 当然，你的C文件和头文件是存在的啦，于是make会生成`.o`文件，然后再用`.o`文件生成make的终极任务，也就是可执行文件` edit `了。

### 3. 使用变量
Makefile中变量为一串字符串，可以类比为C语言中的宏。

由于示例中`.o`文件字符串多次重复且较为复杂不易维护，可以使用变量替代。具体如下：
```Makefile
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o
```
如果要使用该变量，则在makefile中以`$(objects)`方式使用。如果有新的`.o`文件加入，则修改`objects`变量即可。

### 4. 自动推导
GNU的make可以自动推导文件以及文件依赖关系后面的命令，于是我们就没必要去在每一个`.o`文件后都写上类似的命令，因为，我们的make会自动识别，并自己推导命令。

只要make看到一个`.o`文件，它就会自动的把`.c`文件加在依赖关系中，如果make找到一个`whateve.o`，那么`whatever.c`就会是`whateve.o`的依赖文件。并且`cc -c whatever.c`也会被推导出来。所以示例的makefile可以写为：
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
这种方法就是make的“隐式规则”。上面文件内容中，`.PHONY`表示`clean`是个伪目标文件。