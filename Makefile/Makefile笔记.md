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
在一些大工程中会把不同模块或是不同功能的源文件放在不同的目录中，我们可以在每个目录中都书写一个该目录的Makefile，从而使Makefile变得更加简洁。

例如，我们有一个子目录叫subdir，这个目录下有个Makefile文件，来指明了这个目录下文件的编译规则。那么我们总控的Makefile可以这样书写：
```Makefile
subsystem :
    cd subdir && $(MAKE)
```
其等价于：
```Makefile
subsystem :
    $(MAKE) -c subdir
```

此Makefile为“总控Makefile”，总控Makefile的变量可以传递到下级Makefile中，但是不会覆盖下层Makefile中所定义的变量，除非指定 `-e` 参数。默认情况下，只有通过命令行设置的变量会被传递。

对于要传递到下级Makefile变量，其声明为：
```Makefile
export <varible ...>
```
对于不想传递到下级Makefile变量，其声明为：
```Makefile
unexport <varible ...>
```
如果要传递所有变量，则只要一个export即可，后面什么都不用加，表示传递所有变量。

需要注意的是，有两个变量，一个是 `SHELL` ，一个是 `MAKEFLAGS` ，这两个变量不管你是否export，其总是要传递到下层 Makefile中，特别是 `MAKEFLAGS` 变量，其中包含了make的参数信息，如果我们执行“总控Makefile”时有make参数或是在上层 Makefile中定义了这个变量，那么 `MAKEFLAGS` 变量将会是这些参数，并会传递到下层Makefile中，这是一个系统级的环境变量。

但是make命令中的有几个参数并不往下传递，它们是 `-C`, `-f`, `-h`, `-o` 和 `-W` ，如果不想往下层传递参数，则可以：
```Makefile
subsystem:
    cd subdir && $(MAKE) MAKEFLAGS=
```

对于定义了环境变量 `MAKEFLAGS` ，则应当确保其中的选项后续都会用到，如果其中有 `-t`，`-n` 和 `-q` 参数，则可能有意料之外的结果。

在嵌套执行中，`-w` 或 `--print-directory` 可以在make过程中输出信息，显示目前的工作目录。比如，如果我们的下级make目录是“/home/hchen/gnu/make”，如果我们使用 `make -w` 来执行，那么当进入该目录时，我们会看到:
```Makefile
make: Entering directory `/home/hchen/gnu/make'.
```
而在完成下层make后离开目录时，我们会看到:
```Makefile
make: Leaving directory `/home/hchen/gnu/make'
```

当你使用 `-C` 参数来指定make下层Makefile时， `-w` 会被自动打开的。如果参数中有 `-s` （ `--slient` ）或是 `--no-print-directory` ，那么， `-w` 总是失效的。

### 5. 定义命令包
如果Makefile中出现一些相同命令序列，则可以为这些相同的命令序列定义一个变量。定义这种命令序列的语法以 `define` 开始，以 `endef` 结束，如：
```Makefile
define run-yacc
yacc $(firstword $^)
mv y.tab.c $@
endef
```
这里，“run-yacc”是这个命令包的名字，其不要和Makefile中的变量重名。在 `define` 和 `endef` 中的两行就是命令序列。这个命令包中的第一个命令是运行Yacc程序，因为Yacc程序总是生成“y.tab.c”的文件，所以第二行的命令就是把这个文件改改名字。其使用如下：
```Makefile
foo.c : foo.y
    $(run-yacc)
```
此处 `$^` 就是 `foo.y`。

## 五、使用变量
变量的命名字可以包含字符、数字，下划线（可以是数字开头），但不应该含有 `:` 、 `#` 、 `=` 或是空字符（空格、回车等）。变量是大小写敏感的，“foo”、“Foo”和“FOO”是三个不同的变量名。

此外还有自动化变量，如 `$<` 、 `$@`等。

### 1. 变量的基础
变量在声明时需要给予初值，而在使用时，需要在变量名前加上 `$` 符号，但最好使用小括号 `()` 或是大括号 `{}` 将变量包括起来。如果要使用真实的 `$` 字符，则需要用 `$$` 进行表示。

变量可以用在许多地方，如规则中的目标、依赖、命令以及新的变量中，变量会在使用它的地方精确地展开，就像C/C++中的宏一样，如：
```Makefile
objects = prgram.o foo.o utils.o
program : $(objects)
    cc -o program $(objects)

$(objects) : defs.h
```
另外，给变量加上括号完全是为了更加安全地使用这个变量，上述例子中变量可以不加括号。

### 2. 变量中的变量
在定义变量时可以使用其他变量里构造变量，在Makefile中有两种方式使用变量定义变量的值。

1. 使用 `=`，在 `=` 左侧是变量，右侧是变量的值，右侧变量的值可以定义在文件的任何一处，也就是说右侧中的变量不一定是已定义好的值，也可以使用后面定义的值，如：
    ```Makefile
    foo = $(bar)
    bar = $(ugh)
    ugh = Huh?

    all:
        echo $(foo)
    ```
    此类方法优点是可以将变量的真实值推到后面定义，但是缺点是对于递归定义，会让make陷入无限的变量展开过程中。此外，如果在变量中使用函数，则会使make运行非常慢，更糟糕的是，它会使用得两个make的函数“wildcard”和“shell”发生不可预知的错误。因为你不会知道这两个函数会被调用多少次。
2. 使用 `:=` 操作符，可避免上述方式问题。
    ```Makefile
    x := foo
    y := $(x) bar
    x := later
    ```
    其等价于
    ```Makefile
    y := foo bar
    x := later
    ```
    对于此类方法，前面的变量不能使用后面的变量，只能使用前面已经定义好的变量。如果如下例所示：
    ```Makefile
    y := $(x) bar
    x := later
    ```
    则y的值为“bar”，而非“foo bar”。

此外，如果要定义一个变量，其值为空格，则可以这样进行定义：
```Makefile
nullstring :=
space := $(nullstring) # end of the line
```
nullstring是一个Empty变量，其中什么也没有，而我们的space的值是一个空格。因为在操作符的右边是很难描述一个空格的，这里采用的技术很管用，先用一个Empty变量来标明变量的值开始了，而后面采用“#”注释符来表示变量定义的终止，这样，我们可以定义出其值是一个空格的变量。**请注意这里关于“#”的使用，注释符“#”的这种特性值得我们注意**，如果我们这样定义一个变量:
```Makefile
dir := /foo/bar    # directory to put the frobs in
```
则dir变量的值为“/foo/bar”，后面还跟了4个空格，如果使用这个变量来指定别的目录，如“$(dir)/file”则会报错。

还有一个比较有用的操作符是 `?=`，如下例所示：
```Makefile
FOO ?= bar
```
其含义使如果FOO未被定义，则变量FOO的值就是“bar”，如果FOO先前被定义过，则什么也不做。

### 3. 变量高级用法
#### (1) 变量值的替换
我们可以替换变量中共有部分，格式为 `$(var:a=b)` 或是 `${var:a=b}` ，含义是将变量“var”中所有以“a”字串借位的“a”替换为“b”字串。此处“结尾”含义使“空格”或“结束符”。

```Makefile
foo := a.o b.o c.o
bar := $(foo:.o=.c)
```
上例中先定义了一个 `$(foo)` 变量，第二行含义是将 `$(foo)` 中所有以 `.o` 字串借位替换为 `.c`。

另外一种变量替换级数是以静态模式定义的，如：
```Makefile
foo := a.o b.o c.o
bar := $(foo:%.o=%.c)
```
这依赖于被替换字串中有相同模式，模式中必须包含 `%` 字符。

#### (2) 将变量值再作为变量
```Makefile
x = y
y = z
a := $($(x))
```
上例中，`$(x)` 的值是y，所以 `$($(x))` 等价于 `$(y)` ，于是 `$(a)` 的值就是z。

此外，可以在定义中加入函数，如下例所示：
```Makefile
x = variable1
variable2 := Hello
y = $(subst 1,2,$(x))
z = y
a := $($($(z)))
```
`$($($(z)))` 扩展为 `$($(y))` ，而其再次被扩展为 `$($(subst 1,2,$(x)))`。`$(x)` 的值是“variable1”，subst函数把“variable1”中的所有“1”字串替换成“2”字串，于是，“variable1”变成 “variable2”，再取其值，所以，最终， `$(a)` 的值就是 `$(variable2)` 的值——“Hello”。

在这种方式中，可以使用多个变量来组成一个变量的名字，然后再取其值：
```Makefile
first_second = Hello
a = first
b = second
all = $($a_$b)
```
这里的 `$a_$b` 组成了“first_second”，于是，`$(all)` 的值就是“Hello”。

此外，此技术和函数与条件语句可以一同使用
```Makefile
ifdef do_sort
    func := sort
else
    func := strip
endif

bar := a d b g q c

foo := $($(func) $(bar))
```
这个示例中，如果定义了“do_sort”，那么： `foo := $(sort a d b g q c)`，于是 `$(foo)` 的值就是 “a b c d g q”，而如果没有定义“do_sort”，那么： `foo := $(strip a d b g q c)`，调用的就是strip函数。

### 4. 追加变量值
可以使用 `+=` 操作符给变量追加值，如：
```Makefile
objects = main.o foo.o bar.o utils.o
objects += another.o
```
此时 `$(objects)` 变为“main.o foo.o bar.o utils.o another.o”。

如果之前没有定义过，则 `+=` 会自动变成 `=`，如果前面有变量定义，则会继承前次操作的赋值符。如果前一次的是 `:=` ，那么 `+=` 会以 `:=` 作为其赋值符。对于前次的赋值符是 `=`，并不会发生递归定义，make会自动解决该问题。

### 5. override指令
如果有变量是通过make的命令行参数设置的，那么Makefile文件中对这个变量的赋值会被忽略。如果想在Makefile文件中设置参数的值，需要使用 `override` 指令，其语法是：
```Makefile
override <variable>; = <value>;
override <variable>; := <value>;
override <variable>; += <more text>;
```
对于多行的变量定义，使用define指令，在define指令前，同样可以使用override指令，如：
```Makefile
override define foo
bar
endef
```

### 6. 多行变量
还有一种设置变量值的方法是使用define关键字。使用define关键字设置变量的值可以有换行，这有利于定义一系列的命令。

define指令后面跟的是变量的名字，而重起一行定义变量的值，定义是以endef 关键字结束。其工作方式和“=”操作符一样。变量的值可以包含函数、命令、文字，或是其它变量。由于命令需要以 `Tab` 键开头，所以如果define定义的命令变量没有以 `Tab` 键开头，则make不会将其认为是命令。
```Makefile
NAME = Makefile

override define MIX_VAR
@echo "Hello, $(NAME)!"  # 引用其他变量
@echo "当前目录：$(shell pwd)"  # 调用shell函数
@echo "这是多行命令的第三行"
endef

all:
    $(MIX_VAR)
```

### 7. 环境变量
make运行时系统环境变量可以在make开始运行时被载入Maefile文件中，但是如果Makefile中已经定义了这个变量，或这个变量由mak命令行带入，那么系统环境变量的值将被覆盖，除非make指定“-e”参数使系统环境变量覆盖Makefile中定义的变量。

如果在环境变量中设置了 `CFLAGS` 环境变量，则可以在所有的Makefile中使用这个变量，这对于使用统一的编译参数有较大好处。如果Makefile中定义了 `CFLAGS`，那么则会使用Makefile中的这个变量，如果没有定义则使用系统环境变量的值。

当make嵌套调用时，上层Makefile中定义的变量会以系统环境变量的方式传递到下层Makefile中，默认情况下，只有通过命令行设置的变量会被传递。而定义在文件中的变量，如果要向下层Makefile传递，则需要使用export关键字来声明。而定义在文件中的变量，如果要向下层Makefile传递，则需要使用export关键字来声明，具体参考前文嵌套执行make章节。