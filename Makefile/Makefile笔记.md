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
对于存放在不同路径的源文件，当 `make` 去寻找文件的依赖关系时，可以在文件前加上路径，但最好的方法是将一个路径告诉 `make` ，让 `make` 自动去寻找。

Makefile文件中特殊变量 `VPATH` 可以完成这个功能。定义该变量后，`make` 在当前目录找不到的情况下，则会到指定的目录中去寻找文件。
```Makefile
VPATH = src:../headers
```
如上例所示，`make` 将会按照"src"和"../headers"顺序进行搜索，目录由 `:` 进行分隔。当然，当前目录永远是最高优先搜索的地方。

除此以外，还可以使用 `vpath` 关键字，这不是变量而是一个 `make` 关键字，可以指定不同文件在不同搜索目录中。使用方法有三种：
1. 为符合模式 `<pattern>` 的文件指定搜索目录`<directories>`。
```Makefile
vpath <pattern> <directories>
```
2. 清除符合模式 `<pattern>` 的文件的搜索目录。
```Makefile
vpath <pattern>
```
3. 清除所有已被设置好了的文件搜索目录。
```Makefile
vpath
```
vpath中的 `<pattern>` 需要包含 `%` 字符。`%` 字符意思是匹配若干字符。例如`%.h` 表示所有以 `.h` 结尾的文件。`<pattern>` 指定了要搜索的文件集，而 `<directories>` 指定 `<pattern>` 的文件集的搜索目录。

```Makefile
vpath %.h ../headers
```
在上例中要求make在“../headers”目录下搜索所有以 `.h` 结尾的文件。

可以连续使用vpath语句，以指定不同搜索策略。如果连续vpath语句中出现相同或重复的 `<pattern>` ，则按照语句先后顺序进行搜索。
```Makefile
vpath %.c foo:bar
vpath %   blish
```

### 4. 伪目标
```Makefile
clean:
    rm *.o temp
```
在上例中，我们并不生成"clean"这个文件。“伪目标”并非一个文件，只是一个标签，所以make无法生成它的依赖关系和决定它是否要执行，只有通过显式地指明这个“目标”才能让其生效。“伪目标”取名不能和文件名重合，否则失去“伪目标“的意义了。

为了避免和文件重名的这种情况，我们可以使用一个特殊的标记“.PHONY”来显式地指明一个目标是“伪目标”，向make说明，不管是否有这个文件，这个目标就是“伪目标”。

伪目标一般没有依赖的文件。但是，我们也可以为伪目标指定所依赖的文件。伪目标同样可以作为“默认目标”，只要将其放在第一个。
```Makefile
all : prog1 prog2 prog3
.PHONY : all

prog1 : prog1.o utils.o
    cc -o prog1 prog1.o utils.o

prog2 : prog2.o
    cc -o prog2 prog2.o

prog3 : prog3.o sort.o utils.o
    cc -o prog3 prog3.o sort.o utils.o
```
上例中声明了一个"all"的伪目标，依赖于其他三个目标。Makefile中的第一个目标会被作为其默认目标。由于默认目标的特性是，总是被执行的，但由于“all”又是一个伪目标，伪目标只是一个标签不会生成文件，所以不会有“all”文件产生。于是，其它三个目标的规则总是会被决议。也就达到了我们一口气生成多个目标的目的。 

此外，上例表明，目标可以成为依赖。同理，伪目标同样也可成为依赖。
```Makefile
.PHONY : cleanall cleanobj cleandiff

cleanall : cleanobj cleandiff
    rm program

cleanobj :
    rm *.o

cleandiff :
    rm *.diff
```
“make cleanall”将清除所有要被清除的文件。“cleanobj”和“cleandiff”这两个伪目标类似“子程序”的意思。我们可以输入“make cleanall”和“make cleanobj”和“make cleandiff”命令来达到清除不同种类文件的目的。

### 5. 多目标
Makefile的规则中的目标可以不止一个，其支持多目标，有可能我们的多个目标同时依赖于一个文件，并且其生成的命令大体类似。于是我们就能把其合并起来。当然，多个目标的生成规则的执行命令不是同一个，通过使用自动化变量 `$@` 表示目前规则中所有的目标的集合。
```Makefile
bigoutput littleoutput : text.g
    generate text.g -$(subst output,,$@) > $@
```
上述规则等价于：
```Makefile
bigoutput : text.g
    generate text.g -big > bigoutput
littleoutput : text.g
    generate text.g -little > littleoutput
```
其中，`-$(subst output,,$@)` 中的 `$` 表示执行一个Makefile的函数，函数名为subst，后面的为参数。这里的这个函数是替换字符串的意思， `$@` 表示目标的集合，就像一个数组， `$@` 依次取出目标，并执于命令。

### 6. 静态模式
静态模式可以更加容易地定义多目标的规则，可以让我们的规则变得更加有弹性和灵活，语法如下：
```Makefile
<targets ...> : <target-pattern> : <prereq-patterns ...>
    <commands>
    ...
```
1. targets定义了一系列的目标文件，可以有通配符。是目标的一个集合。
2. target-pattern是指明了targets的模式，也就是目标集的模式。
3. prereq-patterns是目标的依赖模式，它对target-pattern形成的模式再进行一次依赖目标的定义。

如果我们的`<target-pattern>`定义成 `%.o` ，意思是我们的 `<target>` 集合中都是以 `.o` 结尾的，而如果我们的 `<prereq-patterns>` 定义成 `%.c` ，意思是对 `<target-pattern>` 所形成的目标集进行二次定义，其计算方法是，取 `<target-pattern>` 模式中的 `%` （也就是去掉了 `.o` 这个结尾），并为其加上 `.c` 这个结尾，形成的新集合。

所以，我们的“目标模式”或是“依赖模式”中都应该有 `%` 这个字符，如果你的文件名中有 `%` 那么你可以使用反斜杠 `\` 进行转义，来标明真实的 `%` 字符。

```Makefile
objects = foo.o bar.o

all: $(objects)

$(objects): %.o: %.c
    $(CC) -c $(CFLAGS) $< -o $@
```

上面的例子中，指明了我们的目标从`$(object)`中获取， `%.o` 表明要所有以 `.o` 结尾的目标，也就是 `foo.o bar.o` ，也就是变量 `$object` 集合的模式，而依赖模式 %.c 则取模式 `%.o` 的 `%` ，也就是 `foo bar` ，并为其加下 `.c` 的后缀，于是，我们的依赖目标就是 `foo.c bar.c` 。而命令中的 `$<` 和 `$@` 则是自动化变量， `$<` 表示第一个依赖文件， `$@` 表示目标集（也就是“foo.o bar.o”）。于是，上面的规则展开后等价于下面的规则：

```Makefile
foo.o : foo.c
    $(CC) -c $(CFLAGS) foo.c -o foo.o
bar.o : bar.c
    $(CC) -c $(CFLAGS) bar.c -o bar.o
```

“静态模式规则”的用法很灵活，如果用得好，那会是一个很强大的功能。参考下例，其中`$(filter %.o,$(files))`表示调用Makefile的filter函数，过滤“$files”集，只要其中模式为“%.o”的内容。：
```Makefile
files = foo.elc bar.o lose.o

$(filter %.o,$(files)): %.o: %.c
    $(CC) -c $(CFLAGS) $< -o $@
$(filter %.elc,$(files)): %.elc: %.el
    emacs -f batch-byte-compile $<
```

### 7. 自动生成依赖性
由于工程中C文件往往包含多个头文件，然而加入或者删除头文件时，也需要修改Makefile。为增加可维护性，可以使用C/C++编译中自动找寻源文件中包含的头文件，并生成一个依赖关系。在C/C++编译器中为"-M"选项，此时编译器自动生成依赖关系。**在GNU的C/C++编译器，应当使用 `-MM` 参数，否则，`-M` 参数会把一些标准库头文件包含进去。**

假设有依赖关系如下：
```Makefile
main.o : main.c defs.h
```
则当执行命令 `cc -M main.c` 后输出为 `main.o : main.c defs.h`。

为将此功能与Makefile联系在一起，让Makefile自己依赖于源文件，GNU组织建议把编译器为每一个源文件的自动生成的依赖关系放到一个文件中，为每一个 `name.c` 的文件都生成一个 `name.d` 的Makefile文件， `.d` 文件中就存放对应 `.c` 文件的依赖关系。

因此，可以通过写出 `.c` 文件和 `.d` 文件的依赖关系，并让make自动更新或生成 `.d` 文件，并把其包含在主Makefile中，就可以自动化地生成每个文件的依赖关系了。

此处为一个模式规则来产生 `.d` 文件：
```Makefile
%.d : %.c
    @set -e; rm -rf $@; \
    $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
    sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
    rm -f $@.$$$$
```
这个规则的意思是，所有的 `.d` 文件依赖于 `.c` 文件， `rm -f $@` 的意思是删除所有的目标，也就是 `.d` 文件，第二行的意思是，为每个依赖文件 `$<` ，也就是 `.c` 文件生成依赖文件， `$@` 表示模式 `%.d` 文件，如果有一个C文件是name.c，那么 `%` 就是 `name` ， `$$$$` 意为一个随机编号，第二行生成的文件有可能是“name.d.12345”，第三行使用sed命令做了一个替换，关于sed命令的用法请参看相关的使用文档。第四行就是删除临时文件。

总而言之，这个模式要做的事就是在编译器生成的依赖关系中加入 `.d` 文件的依赖，即把依赖关系：
```Makefile
main.o : main.c defs.h
```
转换为
```Makefile
main.o main.d : main.c defs.h
```
除了在 `.d` 文件中加入依赖关系外，还可以在文件中加入生成的命令，让每个 `.d` 文件都包含一个完整的规则。

为了将这些自动生成的规则放入主Makefile中，可以使用"include"命令，例如：
```Makefile
sources = foo.c bar.c
include $(sources:.c=.d)
```
上述语句中的 `$(sources:.c=.d)` 中的 `.c=.d` 的意思是做一个替换，把变量 `$(sources)` 所有 `.c` 的字串都替换成 `.d`。因为include是按次序来载入文件，最先载入的 `.d` 文件中的目标会成为默认目标，所以应当注意次序。

## 四、书写命令
与每条规则中的命令和操作系统Shell的命令行是一致的。make会按顺序执行命令，每条命令开头必须以 `Tab` 键开头，除非命令是紧跟在依赖规则后面的分号后的。命令行之间的空格或空行可忽略，但是如果该空格或空行以 `Tab` 键开头，则make会认为其是一个空命令。make的命令默认是被 `/bin/sh` 解释执行的。

### 1. 显示命令
通常，make会把其要执行的命令行在命令执行前输出到屏幕上。当使用 `@` 字符在命令行前，则这个命令将不被make显示出来。例如：
```Makefile
@echo 正在编译模块......
```
当make执行时，会输出“正在编译模块......”字符串，但不会输出命令。如果没有 `@` ，则make将输出：
```shell
echo 正在编译模块......
正在编译模块......
```

如果make执行时，带入参数 `-n` 或 `--just-print` ，则只显示命令，但不会执行命令，有利于调试Makefile。

而参数 `-s` 或 `--silent` 或 `--quiet` 则是全面禁止命令的显示。

### 2. 命令执行
当依赖目标新于目标时，即当前规则的目标需要被更新，则make会执行其后的命令。需要注意的是，如果你要让上一条命令的结果应用在下一条命令时，你应该使用分号分隔这两条命令。比如你的第一条命令是cd命令，你希望第二条命令得在cd之后的基础上运行，那么你就不能把这两条命令写在两行上，而应该把这两条命令写在一行上，用分号分隔。如：
- 示例一：
```Makefile
exec:
    cd /home/lzl
    pwd
```

- 示例二：
```Makefile
exec:
    cd /home/lzl; pwd
```

当执行 `make exec` 时，示例一中cd没有作用，pwd仍然打印当前Makefile目录，示例二则会打印“/home/lzl”。

### 3. 命令出错
每当命令运行完后，make会检测每个命令的返回码，如果命令返回成功，那么make会执行下一条命令，当规则中所有的命令成功返回后，这个规则就算是成功完成了。如果一个规则中的某个命令出错了（命令退出码非零），那么make就会终止执行当前规则，这将有可能终止所有规则的执行。

但是，有些时候命令出错不表示就是错误的。例如，mkdir命令在目录不存在时，简历目录，但是如果目录存在，则会出错。但使用该命令目的为确定由这样一个目录，于是我们不希望mkdir出错而终止规则运行。

为忽略命令出错，可以在Makfile的命令行前加一个 `-` ，标记为不管命令出错与否都认为时成功的。例如：
```Makfile
clean :
    -rm -f *.o
```

此外存在全局解决方案，即给make加上 `-i` 或 `--ignore-errors` 参数，则Makefile中所有命令都会忽略错误。如果一个规则以 `.IGNORE` 为目标，则这个规则中所有命令都会忽略错误。

make中还有参数 `-k` 或 `--keep-going` ，含义是如果规则中的命令出错了，则终止该规则的执行，但继续执行其他规则。

### 4. 嵌套执行make
