# Makefile笔记
---
## 一、简介
笔记参考教程为[文档](https://seisman.github.io/how-to-write-makefile/overview.html)中内容，仅仅是作为学习记录，未经允许不得转载。
## 二、Makefile基础
### 1. Makefile规则
```makefile
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
```makefile
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
```makefile
objects = main.o kbd.o command.o display.o \
    insert.o search.o files.o utils.o
```
如果要使用该变量，则在makefile中以 `$(objects)` 方式使用。如果有新的 `.o` 文件加入，则修改 `objects` 变量即可。

### 4. 自动推导
GNU的make可以自动推导文件以及文件依赖关系后面的命令，于是我们就没必要去在每一个 `.o` 文件后都写上类似的命令，因为，我们的make会自动识别，并自己推导命令。

只要make看到一个 `.o` 文件，它就会自动的把 `.c` 文件加在依赖关系中，如果make找到一个 `whateve.o` ，那么 `whatever.c `就会是 `whateve.o` 的依赖文件。并且 `cc -c whatever.c` 也会被推导出来。所以示例的makefile可以写为：
```makefile
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
```makefile
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
```makefile
clean :
    rm edit $(objects)
```
更为稳健做法为：
```makefile
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
```makefile
include <filenames>...
```
`<filenames>`可以是当前操作系统Shell的文件模式（可以包含路径和通配符）。

在 `include` 前面可以有一些空字符，但是绝不能是 `Tab` 键开始。 `include` 和 `<filenames>` 可以用一个或多个空格隔开。举个例子，你有这样几个Makefile： `a.mk` 、 `b.mk` 、 `c.mk` ，还有一个文件叫 `foo.make` ，以及一个变量 `$(bar)` ，其包含了 `bish` 和 `bash` ，那么，下面的语句：
```makefile
include foo.make *.mk $(bar)
```
等价于
```makefile
include foo.make a.mk b.mk c.mk bish bash
```
make命令开始时，会找寻 `include` 所指出的其它Makefile，并把其内容安置在当前的位置。如果文件都没有指定绝对路径或是相对路径的话，make会在当前目录下首先寻找，如果当前目录下没有找到，那么，make还会在下面的几个目录下找：
1. 如果make执行时，有 `-I `或 `--include-dir` 参数，那么make就会在这个参数所指定的目录下去寻找。
2. 接下来按顺序寻找目录 `<prefix>/include` （一般是 `/usr/local/bin` ）、 `/usr/gnu/include` 、 `/usr/local/include` 、 `/usr/include` 。

环境变量 `.INCLUDE_DIRS` 包含当前 `make` 会寻找的目录列表。应当避免使用命令行参数 `-I` 来寻找以上这些默认目录，否则会使得 `make` “忘掉”所有已经设定的包含目录，包括默认目录。

如果有文件没有找到的话，make会生成一条警告信息，但不会马上出现致命错误。它会继续载入其它的文件，一旦完成makefile的读取，make会再重试这些没有找到，或是不能读取的文件，如果还是不行，make才会出现一条致命信息。如果你想让make不理那些无法读取的文件，而继续执行，你可以在include前加一个减号“-”。如：
```makefile
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
```makefile
targets : prerequisites
    command
    ...
```
或
```makefile
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
```makefile
clean :
    rm -f *.o
```

此外，通配符也可以用在规则中，下例中目标print依赖于所有的 `.c` 文件，其中的 `$?` 是一个自动化变量。
```makefile
print : *.c
    lpr -p $?
    touch print
```

同理，通配符也可以用在变量中。**但在下面需要注意的是，由于类似C语言宏定义，`*.o` 并不会展开，变量objects的值就是 `*.o`。**
```makefile
objects = *.o
```

**如果要让通配符展开，需要使用 `wildcard` 函数进行包裹。** 建议总是使用 `wildcard` 函数进行包裹。可以参考下面例子。
```makefile
objects := $(wildcards *.o)
```

### 3. 文件搜寻
对于存放在不同路径的源文件，当 `make` 去寻找文件的依赖关系时，可以在文件前加上路径，但最好的方法是将一个路径告诉 `make` ，让 `make` 自动去寻找。

Makefile文件中特殊变量 `VPATH` 可以完成这个功能。定义该变量后，`make` 在当前目录找不到的情况下，则会到指定的目录中去寻找文件。
```makefile
VPATH = src:../headers
```
如上例所示，`make` 将会按照"src"和"../headers"顺序进行搜索，目录由 `:` 进行分隔。当然，当前目录永远是最高优先搜索的地方。

除此以外，还可以使用 `vpath` 关键字，这不是变量而是一个 `make` 关键字，可以指定不同文件在不同搜索目录中。使用方法有三种：
1. 为符合模式 `<pattern>` 的文件指定搜索目录`<directories>`。
```makefile
vpath <pattern> <directories>
```
2. 清除符合模式 `<pattern>` 的文件的搜索目录。
```makefile
vpath <pattern>
```
3. 清除所有已被设置好了的文件搜索目录。
```makefile
vpath
```
vpath中的 `<pattern>` 需要包含 `%` 字符。`%` 字符意思是匹配若干字符。例如`%.h` 表示所有以 `.h` 结尾的文件。`<pattern>` 指定了要搜索的文件集，而 `<directories>` 指定 `<pattern>` 的文件集的搜索目录。

```makefile
vpath %.h ../headers
```
在上例中要求make在“../headers”目录下搜索所有以 `.h` 结尾的文件。

可以连续使用vpath语句，以指定不同搜索策略。如果连续vpath语句中出现相同或重复的 `<pattern>` ，则按照语句先后顺序进行搜索。
```makefile
vpath %.c foo:bar
vpath %   blish
```

### 4. 伪目标
```makefile
clean:
    rm *.o temp
```
在上例中，我们并不生成"clean"这个文件。“伪目标”并非一个文件，只是一个标签，所以make无法生成它的依赖关系和决定它是否要执行，只有通过显式地指明这个“目标”才能让其生效。“伪目标”取名不能和文件名重合，否则失去“伪目标“的意义了。

为了避免和文件重名的这种情况，我们可以使用一个特殊的标记“.PHONY”来显式地指明一个目标是“伪目标”，向make说明，不管是否有这个文件，这个目标就是“伪目标”。

伪目标一般没有依赖的文件。但是，我们也可以为伪目标指定所依赖的文件。伪目标同样可以作为“默认目标”，只要将其放在第一个。
```makefile
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
```makefile
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
```makefile
bigoutput littleoutput : text.g
    generate text.g -$(subst output,,$@) > $@
```
上述规则等价于：
```makefile
bigoutput : text.g
    generate text.g -big > bigoutput
littleoutput : text.g
    generate text.g -little > littleoutput
```
其中，`-$(subst output,,$@)` 中的 `$` 表示执行一个Makefile的函数，函数名为subst，后面的为参数。这里的这个函数是替换字符串的意思， `$@` 表示目标的集合，就像一个数组， `$@` 依次取出目标，并执于命令。

### 6. 静态模式
静态模式可以更加容易地定义多目标的规则，可以让我们的规则变得更加有弹性和灵活，语法如下：
```makefile
<targets ...> : <target-pattern> : <prereq-patterns ...>
    <commands>
    ...
```
1. targets定义了一系列的目标文件，可以有通配符。是目标的一个集合。
2. target-pattern是指明了targets的模式，也就是目标集的模式。
3. prereq-patterns是目标的依赖模式，它对target-pattern形成的模式再进行一次依赖目标的定义。

如果我们的`<target-pattern>`定义成 `%.o` ，意思是我们的 `<target>` 集合中都是以 `.o` 结尾的，而如果我们的 `<prereq-patterns>` 定义成 `%.c` ，意思是对 `<target-pattern>` 所形成的目标集进行二次定义，其计算方法是，取 `<target-pattern>` 模式中的 `%` （也就是去掉了 `.o` 这个结尾），并为其加上 `.c` 这个结尾，形成的新集合。

所以，我们的“目标模式”或是“依赖模式”中都应该有 `%` 这个字符，如果你的文件名中有 `%` 那么你可以使用反斜杠 `\` 进行转义，来标明真实的 `%` 字符。

```makefile
objects = foo.o bar.o

all: $(objects)

$(objects): %.o: %.c
    $(CC) -c $(CFLAGS) $< -o $@
```

上面的例子中，指明了我们的目标从`$(object)`中获取， `%.o` 表明要所有以 `.o` 结尾的目标，也就是 `foo.o bar.o` ，也就是变量 `$object` 集合的模式，而依赖模式 %.c 则取模式 `%.o` 的 `%` ，也就是 `foo bar` ，并为其加下 `.c` 的后缀，于是，我们的依赖目标就是 `foo.c bar.c` 。而命令中的 `$<` 和 `$@` 则是自动化变量， `$<` 表示第一个依赖文件， `$@` 表示目标集（也就是“foo.o bar.o”）。于是，上面的规则展开后等价于下面的规则：

```makefile
foo.o : foo.c
    $(CC) -c $(CFLAGS) foo.c -o foo.o
bar.o : bar.c
    $(CC) -c $(CFLAGS) bar.c -o bar.o
```

“静态模式规则”的用法很灵活，如果用得好，那会是一个很强大的功能。参考下例，其中`$(filter %.o,$(files))`表示调用Makefile的filter函数，过滤“$files”集，只要其中模式为“%.o”的内容。：
```makefile
files = foo.elc bar.o lose.o

$(filter %.o,$(files)): %.o: %.c
    $(CC) -c $(CFLAGS) $< -o $@
$(filter %.elc,$(files)): %.elc: %.el
    emacs -f batch-byte-compile $<
```

### 7. 自动生成依赖性
由于工程中C文件往往包含多个头文件，然而加入或者删除头文件时，也需要修改Makefile。为增加可维护性，可以使用C/C++编译中自动找寻源文件中包含的头文件，并生成一个依赖关系。在C/C++编译器中为"-M"选项，此时编译器自动生成依赖关系。**在GNU的C/C++编译器，应当使用 `-MM` 参数，否则，`-M` 参数会把一些标准库头文件包含进去。**

假设有依赖关系如下：
```makefile
main.o : main.c defs.h
```
则当执行命令 `cc -M main.c` 后输出为 `main.o : main.c defs.h`。

为将此功能与Makefile联系在一起，让Makefile自己依赖于源文件，GNU组织建议把编译器为每一个源文件的自动生成的依赖关系放到一个文件中，为每一个 `name.c` 的文件都生成一个 `name.d` 的Makefile文件， `.d` 文件中就存放对应 `.c` 文件的依赖关系。

因此，可以通过写出 `.c` 文件和 `.d` 文件的依赖关系，并让make自动更新或生成 `.d` 文件，并把其包含在主Makefile中，就可以自动化地生成每个文件的依赖关系了。

此处为一个模式规则来产生 `.d` 文件：
```makefile
%.d : %.c
    @set -e; rm -rf $@; \
    $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
    sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
    rm -f $@.$$$$
```
这个规则的意思是，所有的 `.d` 文件依赖于 `.c` 文件， `rm -f $@` 的意思是删除所有的目标，也就是 `.d` 文件，第二行的意思是，为每个依赖文件 `$<` ，也就是 `.c` 文件生成依赖文件， `$@` 表示模式 `%.d` 文件，如果有一个C文件是name.c，那么 `%` 就是 `name` ， `$$$$` 意为一个随机编号，第二行生成的文件有可能是“name.d.12345”，第三行使用sed命令做了一个替换，关于sed命令的用法请参看相关的使用文档。第四行就是删除临时文件。

总而言之，这个模式要做的事就是在编译器生成的依赖关系中加入 `.d` 文件的依赖，即把依赖关系：
```makefile
main.o : main.c defs.h
```
转换为
```makefile
main.o main.d : main.c defs.h
```
除了在 `.d` 文件中加入依赖关系外，还可以在文件中加入生成的命令，让每个 `.d` 文件都包含一个完整的规则。

为了将这些自动生成的规则放入主Makefile中，可以使用"include"命令，例如：
```makefile
sources = foo.c bar.c
include $(sources:.c=.d)
```
上述语句中的 `$(sources:.c=.d)` 中的 `.c=.d` 的意思是做一个替换，把变量 `$(sources)` 所有 `.c` 的字串都替换成 `.d`。因为include是按次序来载入文件，最先载入的 `.d` 文件中的目标会成为默认目标，所以应当注意次序。

## 四、书写命令
与每条规则中的命令和操作系统Shell的命令行是一致的。make会按顺序执行命令，每条命令开头必须以 `Tab` 键开头，除非命令是紧跟在依赖规则后面的分号后的。命令行之间的空格或空行可忽略，但是如果该空格或空行以 `Tab` 键开头，则make会认为其是一个空命令。make的命令默认是被 `/bin/sh` 解释执行的。

### 1. 显示命令
通常，make会把其要执行的命令行在命令执行前输出到屏幕上。当使用 `@` 字符在命令行前，则这个命令将不被make显示出来。例如：
```makefile
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
```makefile
exec:
    cd /home/lzl
    pwd
```

- 示例二：
```makefile
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
```makefile
subsystem :
    cd subdir && $(MAKE)
```
其等价于：
```makefile
subsystem :
    $(MAKE) -c subdir
```

此Makefile为“总控Makefile”，总控Makefile的变量可以传递到下级Makefile中，但是不会覆盖下层Makefile中所定义的变量，除非指定 `-e` 参数。默认情况下，只有通过命令行设置的变量会被传递。

对于要传递到下级Makefile变量，其声明为：
```makefile
export <varible ...>
```
对于不想传递到下级Makefile变量，其声明为：
```makefile
unexport <varible ...>
```
如果要传递所有变量，则只要一个export即可，后面什么都不用加，表示传递所有变量。

需要注意的是，有两个变量，一个是 `SHELL` ，一个是 `MAKEFLAGS` ，这两个变量不管你是否export，其总是要传递到下层 Makefile中，特别是 `MAKEFLAGS` 变量，其中包含了make的参数信息，如果我们执行“总控Makefile”时有make参数或是在上层 Makefile中定义了这个变量，那么 `MAKEFLAGS` 变量将会是这些参数，并会传递到下层Makefile中，这是一个系统级的环境变量。

但是make命令中的有几个参数并不往下传递，它们是 `-C`, `-f`, `-h`, `-o` 和 `-W` ，如果不想往下层传递参数，则可以：
```makefile
subsystem:
    cd subdir && $(MAKE) MAKEFLAGS=
```

对于定义了环境变量 `MAKEFLAGS` ，则应当确保其中的选项后续都会用到，如果其中有 `-t`，`-n` 和 `-q` 参数，则可能有意料之外的结果。

在嵌套执行中，`-w` 或 `--print-directory` 可以在make过程中输出信息，显示目前的工作目录。比如，如果我们的下级make目录是“/home/hchen/gnu/make”，如果我们使用 `make -w` 来执行，那么当进入该目录时，我们会看到:
```makefile
make: Entering directory `/home/hchen/gnu/make'.
```
而在完成下层make后离开目录时，我们会看到:
```makefile
make: Leaving directory `/home/hchen/gnu/make'
```

当你使用 `-C` 参数来指定make下层Makefile时， `-w` 会被自动打开的。如果参数中有 `-s` （ `--slient` ）或是 `--no-print-directory` ，那么， `-w` 总是失效的。

### 5. 定义命令包
如果Makefile中出现一些相同命令序列，则可以为这些相同的命令序列定义一个变量。定义这种命令序列的语法以 `define` 开始，以 `endef` 结束，如：
```makefile
define run-yacc
yacc $(firstword $^)
mv y.tab.c $@
endef
```
这里，“run-yacc”是这个命令包的名字，其不要和Makefile中的变量重名。在 `define` 和 `endef` 中的两行就是命令序列。这个命令包中的第一个命令是运行Yacc程序，因为Yacc程序总是生成“y.tab.c”的文件，所以第二行的命令就是把这个文件改改名字。其使用如下：
```makefile
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
```makefile
objects = prgram.o foo.o utils.o
program : $(objects)
    cc -o program $(objects)

$(objects) : defs.h
```
另外，给变量加上括号完全是为了更加安全地使用这个变量，上述例子中变量可以不加括号。

### 2. 变量中的变量
在定义变量时可以使用其他变量里构造变量，在Makefile中有两种方式使用变量定义变量的值。

1. 使用 `=`，在 `=` 左侧是变量，右侧是变量的值，右侧变量的值可以定义在文件的任何一处，也就是说右侧中的变量不一定是已定义好的值，也可以使用后面定义的值，如：
    ```makefile
    foo = $(bar)
    bar = $(ugh)
    ugh = Huh?

    all:
        echo $(foo)
    ```
    此类方法优点是可以将变量的真实值推到后面定义，但是缺点是对于递归定义，会让make陷入无限的变量展开过程中。此外，如果在变量中使用函数，则会使make运行非常慢，更糟糕的是，它会使用得两个make的函数“wildcard”和“shell”发生不可预知的错误。因为你不会知道这两个函数会被调用多少次。
2. 使用 `:=` 操作符，可避免上述方式问题。
    ```makefile
    x := foo
    y := $(x) bar
    x := later
    ```
    其等价于
    ```makefile
    y := foo bar
    x := later
    ```
    对于此类方法，前面的变量不能使用后面的变量，只能使用前面已经定义好的变量。如果如下例所示：
    ```makefile
    y := $(x) bar
    x := later
    ```
    则y的值为“bar”，而非“foo bar”。

此外，如果要定义一个变量，其值为空格，则可以这样进行定义：
```makefile
nullstring :=
space := $(nullstring) # end of the line
```
nullstring是一个Empty变量，其中什么也没有，而我们的space的值是一个空格。因为在操作符的右边是很难描述一个空格的，这里采用的技术很管用，先用一个Empty变量来标明变量的值开始了，而后面采用“#”注释符来表示变量定义的终止，这样，我们可以定义出其值是一个空格的变量。**请注意这里关于“#”的使用，注释符“#”的这种特性值得我们注意**，如果我们这样定义一个变量:
```makefile
dir := /foo/bar    # directory to put the frobs in
```
则dir变量的值为“/foo/bar”，后面还跟了4个空格，如果使用这个变量来指定别的目录，如“$(dir)/file”则会报错。

还有一个比较有用的操作符是 `?=`，如下例所示：
```makefile
FOO ?= bar
```
其含义使如果FOO未被定义，则变量FOO的值就是“bar”，如果FOO先前被定义过，则什么也不做。

### 3. 变量高级用法
#### (1) 变量值的替换
我们可以替换变量中共有部分，格式为 `$(var:a=b)` 或是 `${var:a=b}` ，含义是将变量“var”中所有以“a”字串借位的“a”替换为“b”字串。此处“结尾”含义使“空格”或“结束符”。

```makefile
foo := a.o b.o c.o
bar := $(foo:.o=.c)
```
上例中先定义了一个 `$(foo)` 变量，第二行含义是将 `$(foo)` 中所有以 `.o` 字串借位替换为 `.c`。

另外一种变量替换级数是以静态模式定义的，如：
```makefile
foo := a.o b.o c.o
bar := $(foo:%.o=%.c)
```
这依赖于被替换字串中有相同模式，模式中必须包含 `%` 字符。

#### (2) 将变量值再作为变量
```makefile
x = y
y = z
a := $($(x))
```
上例中，`$(x)` 的值是y，所以 `$($(x))` 等价于 `$(y)` ，于是 `$(a)` 的值就是z。

此外，可以在定义中加入函数，如下例所示：
```makefile
x = variable1
variable2 := Hello
y = $(subst 1,2,$(x))
z = y
a := $($($(z)))
```
`$($($(z)))` 扩展为 `$($(y))` ，而其再次被扩展为 `$($(subst 1,2,$(x)))`。`$(x)` 的值是“variable1”，subst函数把“variable1”中的所有“1”字串替换成“2”字串，于是，“variable1”变成 “variable2”，再取其值，所以，最终， `$(a)` 的值就是 `$(variable2)` 的值——“Hello”。

在这种方式中，可以使用多个变量来组成一个变量的名字，然后再取其值：
```makefile
first_second = Hello
a = first
b = second
all = $($a_$b)
```
这里的 `$a_$b` 组成了“first_second”，于是，`$(all)` 的值就是“Hello”。

此外，此技术和函数与条件语句可以一同使用
```makefile
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
```makefile
objects = main.o foo.o bar.o utils.o
objects += another.o
```
此时 `$(objects)` 变为“main.o foo.o bar.o utils.o another.o”。

如果之前没有定义过，则 `+=` 会自动变成 `=`，如果前面有变量定义，则会继承前次操作的赋值符。如果前一次的是 `:=` ，那么 `+=` 会以 `:=` 作为其赋值符。对于前次的赋值符是 `=`，并不会发生递归定义，make会自动解决该问题。

### 5. override指令
如果有变量是通过make的命令行参数设置的，那么Makefile文件中对这个变量的赋值会被忽略。如果想在Makefile文件中设置参数的值，需要使用 `override` 指令，其语法是：
```makefile
override <variable> = <value>;
override <variable> := <value>;
override <variable> += <more text>;
```
对于多行的变量定义，使用define指令，在define指令前，同样可以使用override指令，如：
```makefile
override define foo
bar
endef
```

### 6. 多行变量
还有一种设置变量值的方法是使用define关键字。使用define关键字设置变量的值可以有换行，这有利于定义一系列的命令。

define指令后面跟的是变量的名字，而重起一行定义变量的值，定义是以endef 关键字结束。其工作方式和“=”操作符一样。变量的值可以包含函数、命令、文字，或是其它变量。由于命令需要以 `Tab` 键开头，所以如果define定义的命令变量没有以 `Tab` 键开头，则make不会将其认为是命令。
```makefile
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

### 8. 目标变量
之前所介绍的在Makefile中定义的变量均为**全局变量**，在整个文件中都可以访问。当然，自动化变量除外，对于如 `$<` 等自动化变量属于**规则型变量**，其值依赖于规则的目标与依赖目标定义。

此外，也可以为某个目标设置局部变量（Target-specific Variable），其可以与全局变量同名，作用范围只限于这条规则及连带规则中，其值有只在作用范围内有效，而不会影响链以外全局变量的值。其语法如下：
```makefile
<target ...> : <variable-assignment>

<target ...> : override <variable-assignment>
```

`<variable-assignment>` 可以是前面讲过的各种赋值表达式，如 `=` 、 `:=` 、 `+=` 或是 `?=` 。第二个语法是针对于make命令行带入的变量，或是系统环境变量。当设置该变量，则这个变量会作用到这个目标所引发的所有规则中去。

```makefile
prog : CFLAGS = -g
prog : prog.o foo.o bar.o
    $(CC) $(CFLAGS) prog.o foo.o bar.o

prog.o : prog.c
    $(CC) $(CFLAGS) prog.c

foo.o : foo.c
    $(CC) $(CFLAGS) foo.c

bar.o : bar.c
    $(CC) $(CFLAGS) bar.c
```
在这个示例中，不管全局的 `$(CFLAGS)` 的值是什么，在prog目标，以及其所引发的所有规则中（prog.o foo.o bar.o的规则）， `$(CFLAGS)` 的值都是 `-g`。

### 9. 模式变量
在make中，支持模式变量（Pattern-specific Variable）。模式变量支持给定一种模式，将变量定义在符合这种模式的所有目标上。

如下所示，可以给所有 `.o` 结尾的目标定义目标变量
```makefile
%.o : CFLAGS = -O
```
其语法如下：
```makefile
<pattern ...> : <variable-assignment>

<pattern ...> : override <variable-assignment>
```

## 六、使用条件判断
### 1. 示例
```makefile
libs_for_gcc = -lgnu
normal_libs =

foo: $(objects)
ifeq ($(CC),gcc)
    $(CC) -o foo $(objects) $(libs_for_gcc)
else
    $(CC) -o foo $(objects) $(normal_libs)
endif
```
上例中，目标 `foo` 可根据变量 `$(CC)` 值选取不同函数库编译程序。`ifeq` 表示条件语句开始，并指定一个条件表达式，表达式包含两个参数，以逗号分隔，表达式以原括号起。`else` 表示条件表达式为假的情况。`endif` 表示一个条件语句的结束，任何一个条件表达式都应该以 `endif` 结束。

上例可以写得更简洁一些：
```makefile
libs_for_gcc = -lgnu
normal_libs =

ifeq ($(CC),gcc)
    libs=$(libs_for_gcc)
else
    libs=$(normal_libs)
endif

foo: $(objects)
    $(CC) -o foo $(objects) $(libs)
```

### 2. 语法
条件表达式语法为：
```makefile
<conditional-directive>
<text-if-true>
else
<text-if-false>
endif
```
其中 `<conditional-directive>` 表示条件关键字，这类关键字共4个。

1. `ifeq`
`ifeq` 为比较参数 `arg1` 和 `arg2` 的值是否相同，参数中可以使用make的函数。其语法为：
    ```makefile
    ifeq (<arg1>, <arg2>)
    ifeq '<arg1>' '<arg2>'
    ifeq "<arg1>" "<arg2>"
    ifeq "<arg1>" '<arg2>'
    ifeq '<arg1>' "<arg2>"
    ```

2. `ifneq`
`ifneq` 比较参数 `arg1` 和 `arg2` 的值是否不同，与 `ifeq` 类似。其语法如下：
    ```makefile
    ifneq (<arg1>, <arg2>)
    ifneq '<arg1>' '<arg2>'
    ifneq "<arg1>" "<arg2>"
    ifneq "<arg1>" '<arg2>'
    ifneq '<arg1>' "<arg2>"
    ```

3. `ifdef`
`ifdef` 检查变量 `<variable-name>` 值是否非空，如果值非空，则表达式为真，否则为假。`<variable-name>` 同样可以为一个函数的返回值。其语法如下：
    ```makefile
    ifdef <variable-name>
    ```
    需要注意的是，`ifdef`只是测试一个变量是否有值，其并不会把变量扩展到当前位置。
    ```makefile
    bar =
    foo = $(bar)
    ifdef foo
        frobozz = yes
    else
        frobozz = no
    endif
    ```
    和
    ```makefile
    bar =
    foo = $(bar)
    ifdef foo
        frobozz = yes
    else
        frobozz = no
    endif
    ```
    第一个例子中，`$(frobozz)` 值是 `yes` ，第二个则是 `no`。
4. `ifndef`
`ifndef` 检查变量 `<variable-name>` 值是否为空，与 `ifdef` 类似，含义与之相反。其语法如下：
    ```makefile
    ifndef <variable-name>
    ```

在 `<conditional-directive>` 中，多余的空格是被允许的，但不能以 `Tab` 键作为开始，否则被认为是命令。注释符 `#` 同样是安全的。`else` 和 `endif` 同样。

## 七、使用函数
Makefile支持使用函数处理变量，从而使命令或规则更为灵活和只能。函数调用后，函数的返回值可以当作变量来使用。

### 1. 函数调用语法
函数调用，类似变量使用，使用 `$` 进行表示，语法如下：
```makefile
$(<function> <arguments>)

${<function> <arguments>}
```
此处 `<function>` 就是函数名，make所支持的函数并不多。`<arguments>` 为函数参数，参数间以逗号 `,` 分隔，函数名和参数间以空格分割。函数中的参数可以使用变量，为风格统一，函数和变量的括号最好一致，如使用 `$(subst a,b,$(x))` 形式。

### 2. 字符串处理函数
#### (1) subst
```makefile
$(subst <from>,<to>,<text>)
```
- 名称：字符串替换函数
- 功能：将字符串 `<text>` 中的 `<from>` 字符串替换为 `<to>`。
- 返回：函数返回被替换后的字符串。
- 示例：
    ```makefile
    $(subst ee,EE,feet on the street)
    ```
    将 `feet on the street` 中的 `ee` 替换为 `EE`，返回结果是 `fEEt on the strEEt`。

#### (2) patsubst
```makefile
$(patsubst <pattern>,<replacement>,<text>)
```
- 名称：模式字符串替换函数
- 功能：查找 `<text>` 中的单词（单词以“空格”、“Tab”或“回车”“换行”分隔）是否符合模式 `<pattern>`，如果匹配则以 `<replacement>` 替换。`<pattern>` 可以包括通配符 `%`，表示任意长度字符串。如果 `<replacement>` 中也包含 `%` ，那么， `<replacement>` 中的这个 `%` 将是 `<pattern>` 中的那个 `%` 所代表的字串。（可以用 `\` 来转义，以 `\%` 来表示真实含义的 `%` 字符）。
- 返回：函数返回被替换过后的字符串。
- 示例：
    ```makefile
    $(patsubst %.c,%.o,x.c.c bar.c)
    ```
    返回结果为 `x.c.o bar.o`。

#### (3) strip
```makefile
$(strip <string>)
```
- 名称：去除空格函数
- 功能：去掉 `<string>` 字符串中**开头和结尾**的空字符串。
- 返回：去除空格后的字符串值。
- 示例：
    ```makefile
    $(strip a b c )
    ```
    返回结果为 `a b c`。

#### (4) findstring
```makefile
$(findstring <find>,<in>)
```
- 名称：查找字符串函数
- 功能：在字符串 `<in>` 中查找 `<find>` 字串。
- 返回：如果找到，那么返回 `<find>`，否则返回空字符串。
- 示例：
    ```makefile
    $(findstring a,a b c)
    $(findstring a,b c)
    ```
    第一个函数返回 `a` 字符串，第二个返回空字符串。

#### (5) filter
```makefile
$(filter <patern...>,<text>)
```
- 名称：过滤函数
- 功能：以 `<pattern>` 模式过滤 `<text>` 字符串中的单词，保留符合模式 `<pattern>` 的单词。可以有多个模式。
- 返回：返回符合模式 `<pattern>` 的字符串。
- 示例：
    ```makefile
    sources := foo.c bar.c baz.s ugh.h
    foo : $(sources)
        cc $(filter %.c %.s, $(sources)) -o foo
    ```
    `$(filter %.c %.s, $(sources))` 返回值为 `foo.c bar.c baz.s`。

#### (6) filter-out
```makefile
$(filter-out <patern...>,<text>)
```
- 名称：反过滤函数
- 功能：以 `<pattern>` 模式过滤 `<text>` 字符串中的单词，去除符合模式 `<pattern>` 的单词。可以有多个模式。
- 返回：返回不符合模式 `<pattern>` 的字符串。

#### (7) sort
```makefile
$(sort <list>)
```
- 名称：排序函数
- 功能：给字符串 `<list>` 中的单词**升序**排序。
- 返回：排序后的字符串
- 示例：`$(sort foo bar lose)` 返回 `bar foo lose`。
- 备注： `sort` 函数会去掉 `<list>` 中相同的单词。

#### (8) word
```makefile
$(word <n>,<text>)
```
- 名称：取单词函数
- 功能：取字符串 `<text>` 中的第 `<n>` 个单词。
- 返回：回字符串 `<text>` 中第 `<n>` 个单词。如果 `<n>` 比 `<text>` 中的单词数要大，那么返回空字符串。

#### (9) wordlist
```makefile
$(wordlist <ss>,<e>,<text>)
```
- 名称：取单词串函数
- 功能：从字符串 `<text>` 中取 `<ss>` 开始到 `<e>` 的单词串。`<ss>` 和 `<e>` 是一个数字。
- 返回：返回字符串 `<text>` 中从 `<ss>` 到 `<e>` 的单词字串。如果 `<ss>` 比 `<text>` 中的单词数要大，那么返回空字符串。如果 `<e>` 大于 `<text>` 的单词数，那么返回从 `<ss>` 开始，到 `<text>` 结束的单词串。
- 示例：`$(wordlist 2, 3, foo bar baz)` 返回值是 `bar baz`。

#### (10) words
```makefile
$(words <text>)
```
- 名称：单词个数统计函数
- 功能：返回 `<text>` 中字符串中的单词个数。
- 返回：返回 `<text>` 中的单词数。
- 备注：如果我们要取 `<text>` 中最后的一个单词，我们可以这样： `$(word $(words <text>),<text>)` 。

#### (11) firstword
```makefile
$(firstword <text>)
```
- 名称：取首单词函数
- 功能：取字符串 `<text>` 中第一个单词。
- 返回：返回字符串 `<text>` 中的第一个单词。
- 备注：此函数可以使用 `word` 函数实现：`$(word 1,<text>)`。

以上为所有字符串操作函数，混合搭配可以完成比较复杂功能。例如，由于make使用 `VPATH` 指定依赖文件搜索路径，可以利用搜索路径来指定编译器对头文件的搜索路径参数 `CFLAGS`，如：
```makefile
override CFLAGS += $(patsubst %,-I%,$(subst :, ,$(VPATH)))
```
如果 `$(VPATH)` 值是 `src:../headers` ，那么 `$(patsubst %,-I%,$(subst :, ,$(VPATH)))` 将返回 `-Isrc -I../headers` ，这正是cc或gcc搜索头文件路径的参数。

### 3. 文件名操作函数
#### (1) dir
```makefile
$(dir <names...>)
```
- 名称：取目录函数
- 功能：从文件名序列 `<names>` 中阙处目录部分。目录部分是指最后一个反斜杠 `/` 之前的部分。如果没有反斜杠，则返回 `./`。
- 返回：返回文件名序列 `<names>` 的目录部分。
- 示例： `$(dir src/foo.c hacks)` 返回值为 `src/ ./`。
  
#### (2) notdir
```makefile
$(notdir <names...>)
```
- 名称：取文件函数
- 功能：从文件名序列 `<names>` 中取出非目录部分。非目录部分是指最后一个反斜杠 `/` 之后的部分。
- 返回：返回文件名序列 `<names>` 的非目录部分。
- 示例： `$(notdir src/foo.c hacks)` 返回值为 `foo.c hacks`。

#### (3) suffix
```makefile
$(suffix <names...>)
```
- 名称：取后缀函数
- 功能：从文件名序列 `<names>` 中取出各个文件名的后缀。
- 返回：返回文件名序列 `<names>` 的后缀序列，如果文件没有后缀，则返回空字符串。
- 示例：`$(suffix src/foo.c src-1.0/bar.c hacks)` 返回值为 `.c .c`。

#### (4) basename
```makefile
$(basename <names...>)
```
- 名称：取前缀函数
- 功能：从文件名序列 `<names>` 中取出各个文件名的前缀部分。
- 返回：返回文件名序列 `<names>` 的前缀序列，如果文件没有前缀，则返回空字串。
- 示例：`$(basename src/foo.c src-1.0/bar.c hacks)` 返回值为 `src/foo src-1.0/bar hacks`。

#### (5) addsuffix
```makefile
$(addsuffix <suffix>,<names...>)
```
- 名称：加后缀函数
- 功能：将后缀 `<suffix>` 加到 `<names>` 中的每个单词后面。
- 返回：返回加过后缀的文件名序列。

#### (6) addprefix
```makefile
$(addprefix <prefix>,<names...>)
```
- 名称：加前缀函数
- 功能：将前缀 `<prefix>` 加到 `<names>` 中的每个单词前面。
- 返回：返回加过前缀的文件名序列。

#### (7) join
```makefile
$(join <list1>,<list2>)
```
- 名称：连接函数
- 功能：将 `<list2>` 中的单词对应地加到 `<list1>` 的单词后面。如果 `<list1>` 的单词个数要比 `<list2>` 的多，则 `<list1>` 中多出来的单词将保持原样。如果 `<list2>` 的单词个数要比 `<list1>` 的多，则 `<list2>` 中多出来的单词将被复制到 `<list1>` 中。
- 返回：连接过后的字符串。
- 示例：`$(join aaa bbb , 111 222 333)` 返回值是 `aaa111 bbb222 333`。

### 4. foreach函数
该函数不同于其他函数，用于循环，语法如下：
```makefile
$(foreach <var>,<list>,<text>)
```
该函数含义为，将参数 `<list>` 中的单词逐一取出放到参数 `<var>` 所指定的变量中，然后执行 `<text>` 所包含的表达式。每一次 `<text>` 会返回一个字符串，循环过程中，`<text>` 所返回的每个字符串会以空格分隔，最后整个循环结束是，`<text>` 所返回的每个字符串所组成的整个字符串（以空格分隔）将会是foreach函数的返回值。

所以，`<var>` 最好是一个变量名，`<list>` 可以是一个表达式，而 `<text>` 一般使用 `<var>` 这一参数一次枚举 `<list>` 中的单词。需要注意的是，foreach中的 `<var>` 参数为一个临时局部变量，函数执行完成后，参数 `<var>` 变量将不在作用，其作用域只在foreach函数中。

```makefile
names := a b c d
files := $(foreach n, $(names),$(n).o)
```
如上例所示，`$(name)` 中的单词会被取出，并存入变量 `n` 中，`$(n).o` 每次根据 `$(n)` 计算出一个值，这些值以空格分隔，最后作为foreach函数的返回，所以， `$(files)` 的值是 `a.o b.o c.o d.o`。

### 5. if函数
类似 `ifeq` ，if函数语法为：
```makefile
$(if <condition>,`<then-part>`)
$(if <condition>,<then-part>,<else-part>)
```
`<condition>` 参数是if表达式，如果其返回的为非空字符串，则表达式相当于返回真，则 `<then-part>` 会被计算，否则 `<else-part>` 会被计算。

if函数返回值是，如果 `<condition>` 为真（非空字符串），那个 `<then-part>` 会是整个函数的返回值，如果 `<condition>` 为假（空字符串），那么 `<else-part>` 会是整个函数的返回值，此时如果 `<else-part>` 没有被定义，那么，整个函数返回空字串。

### 6. call函数
**call函数是唯一一个可以用来创建新的参数化的函数。**可以写一个非常复杂的表达式，在表达式中定义多个参数，然后使用call函数想表达式传递参数。其语法是：
```makefile
$(call <expression>,<parm1>,<parm2>,...,<parmn>)
```
当执行该函数时，`<expression>` 参数中的变量，如 `$(1)`、`$(2)` 等，会被参数 `<parm1>`、`<parm2>`、`<parm3>` 依次取代。而 `<expression>` 返回值就是call函数返回值。
```makefile
reverse = $(2) $(1)

foo = $(call reverse,a,b)
```
上例中，`foo` 的值就是 `b a`。

需要注意的时，在向call函数传递参数时要尤其注意空格的使用。call函数在处理参数时，第2个及其之后的参数中的空格会被保留，因而可能造成一些奇怪的效果。因而在向call函数提供参数时，最安全的做法是去除所有多余的空格。

### 7. origin函数
origin函数不操作变量的值，而只是告诉变量来源，其语法如下：
```makefile
$(origin <variable>)
```
**注意，`<variable>` 是变量的名字，不应该是引用。所以你最好不要在 `<variable>` 中使用 `$` 字符。**origin函数会以其返回值告知该变量情况，下列为origin函数返回值：
- `undefined`：如果 `<varaible>` 从来没有定义过，则返回 `undefined`。
- `default`：如果 `<variable>` 是一个默认的定义，则返回 `default`。
- `environment`：如果 `<variable>` 是一个环境变量，并且当 Makefile被执行时未打开 `-e` 参数。
- `file`：如果 `<variable>` 被定义在Makefile中。
- `command line`：如果 `<variable>` 变量是被命令行定义的。
- `override`：如果 `<variable>` 是被override指示符重新定义的。
- `automatic`：如果 `<variable>` 是一个命令运行中的自动化变量。

> 这些信息对于编写Makefile是非常有用的，例如，假设我们有一个Makefile其包了一个定义文件 Make.def，在Make.def中定义了一个变量“bletch”，而环境中也有一个环境变量“bletch”，此时，我们想判断一下，如果变量来源于环境，那么我们就把它重定义了，如果来源于Make.def或是命令行等非环境的，那么我们就不重新定义它。
> 当然，override也可以达到相同重新定义效果，但其过于粗暴，会将命令行定义的变量也覆盖了，而我们只想重新定义环境传来的，而不想定义命令行传来的。

### 8. shell函数
shell函数参数未操作系统shell的命令，与反引号“`”有相同功能，即把执行操作系统命令后的输出作为函数返回，如：
```makefile
contents := $(shell cat foo)
files := $(shell echo *.c)
```
此函数会新生成一个Shell程序来执行命令，因此应当注意运行性能，当Makefile中存在一些较复杂的规则并大量使用了这个函数，额对于系统性能是有害的。

### 9. 控制make的函数
make提供了一些函数来控制make的运行。当需要检测Makefile运行时信息，并根据信息来决定make继续执行还是停止。

```makefile
$(error <text...>)
```
产生一个致命的错误，`<text...>` 是错误信息。注意，error函数不会在一被使用就会产生错误信息，所以如果将其定义在某个变量中，并在后续的脚本中使用这个变量，那么也是可以的。

```makefile
$(warning <text...>)
```
该函数类似error函数，只是它并不会让make退出，只是输出一段警告信息，而make继续执行。

## 八、make的运行
### 1. make的退出码
- **0**：表示成功执行。
- **1**：如果make运行时出现任何错误，返回1.
- **2**：如果使用 `-q` 选项，并且make使得一些目标不需要更新，则返回2。

### 2. 指定Makefile
GNU make找寻默认的Makefile的规则是在当前目录下依次找三个文件——“GNUmakefile”、“makefile”和“Makefile”。其按顺序找这三个文件，一旦找到，就开始读取这个文件并执行。

也可以给make指定一个特殊名字的Makefile。则需要使用 `-f` 、`--file` 或 `--makefile` 参数。如果指定makefile名称为`test.mk`，则指令为 `make -f test.mk`。

如果在make的命令行时，不只一次地使用了 `-f` 参数，那么，所有指定的makefile将会被连在一起传递给make执行。

### 3. 指定目标
一般来说，make的最终目标是makefile中第一个目标，而其他目标一般是由这个目标连带出来的。为指定目标，仅需再make命令后直接跟目标名字即可。

任何makefile中的目标都可以被指定为终极目标，但是除了 `-` 开头，或是包含 `=` 的目标，原因在于有这些字符的目标会被解析为命令行参数或变量。甚至未被明确写出的目标也可以成为make的终极目标，即只要make可以找到其隐含规则推到规则，则这个隐含目标同样可以被指定成终极目标。

make中环境变量 `MAKECMDGOALS` 会存放所指定的终极目标列表，如果未指定目标，则变量为空值。

```makefile
sources = foo.c bar.c
ifneq ($(MAKECMDGOALS),clean)
    include $(sources:.c=.d)
endif
```
上例为环境变量 `MAKECMDGOALS` 使用示例，只要所输入指令不为 `make clean`，则makefile自动包含 `foo.d` 和 `bar.d` 文件。

由于make可以指定所有makefile中的目标，包括伪目标，所以可以依据这种特性让makefile一句不同目标完成不同工作。可以参照以下规则书写makefile中的目标。

- all: 该伪目标是所有目标的目标，功能一般是编译所有目标。
- clean: 该伪目标功能是删除所有别make创建的文件。
- install: 该伪目标功能是安装已编译好的程序，即吧目标执行文件复制到指定的目标中去。
- print: 该伪目标功能是列出改变过的源文件。
- tar: 该伪目标功能是将源程序打包备份。
- dist: 该伪目标功能是创建一个压缩文件，一般是将tar文件压缩为Z文件或gz文件。
- TAGS: 该伪目标功能是更新所有目标，以备完整地重编译使用。
- check和test: 这两个伪目标一般用于测试makefile流程

### 4. 检查规则
有时，为检查命令，或是执行的序列，不希望makefile中规则执行起来，则可以使用下述参数

- `-n`, `--just-print`, `--dry-run`, `--recon`
    不执行参数，这些参数只是打印命令，不管目标是否更新，将规则和连带规则下的命令打印出来，但不执行。
- `-t`, `--touch`
    将目标文件的时间更新，但不更改目标文件。即make假装编译目标，但并不是真正的编译目标，只是把木匾编程已编译过的状态。
- `-W <file>`, `--what-if=<file>`, `--assume-new=<file>`, `--new-file=<file>`
    此参数需要指定一个文件，一般是源文件或依赖文件，make根据规则推导来运行依赖于这个文件的命令，一般可以和 `-n` 参数一同使用，来查看依赖文件所发生的规则命令。

### 5. make的参数
下面列举了所有GNU make 3.80版的参数定义。具体参数参考文档。
- `-b`, `-m`
    忽略和其他版本make的兼容性。
- `-B`, `--always-make`
    认为所有的目标都需要重编译。
- `-C <dir>`, `--directory=<dir>`
    指定读取makefile的目录。如果有多个“-C”参数，make的解释是后面的路径以前面的作为相对路径，并以最后的目录作为被指定目录。如：“make -C ~hchen/test -C prog”等价于“make -C ~hchen/test/prog”。
- `-debug[=<options>]`
    输出make的调试信息。它有几种不同的级别可供选择，如果没有参数，那就是输出最简单的调试信息。下面是 `<options>` 的取值：
    - `a`: 也就是all，输出所有的调试信息。（会非常的多）
    - `b`: 也就是basic，只输出简单的调试信息。即输出不需要重编译的目标。
    - `v`: 也就是verbose，在 `b` 选项的级别之上。输出的信息包括哪个makefile被解析，不需要被重编译的依赖文件（或是依赖目标）等。
    - `i`: 也就是implicit，输出所有的隐含规则。
    - `j`: 也就是jobs，输出执行规则中命令的详细信息，如命令的PID、返回码等。
    - `m`: 也就是makefile，输出make读取makefile，更新makefile，执行makefile的信息。
- `-d`
    相当于 `-debug=a`。
- `-e`, `--environment-overrides`
    指明环境变量的值覆盖makefile中定义的变量的值。
- `-f=<file>`, `--file=<file>`, `--makefile=<file>`
    指定需要执行的makefile。
- `-h`, `--help`
    显示帮助信息。
- `-i`, `--ignore-errors`
    在执行时忽略所有的错误。
- `-I <dir>`, `--include-dir=<dir>`
    指定一个被包含makefile的搜索目标。可以使用多个“-I”参数来指定多个目录。

- `-j [<jobsnum>]`, `--jobs[=<jobsnum>]`
    指同时运行命令的个数。如果没有这个参数，make运行命令时能运行多少就运行多少。如果有一个以上的“-j”参数，那么仅最后一个“-j”才是有效的。（注意这个参数在MS-DOS中是无用的）

- `-k`, `--keep-going`
    出错也不停止运行。如果生成一个目标失败了，那么依赖于其上的目标就不会被执行了。

- `-l <load>`, `--load-average[=<load>]`, `-max-load[=<load>]`
    指定make运行命令的负载。

- `-n`, `--just-print`, `--dry-run`, `--recon`
    仅输出执行过程中的命令序列，但并不执行。

- `-o <file>`, `--old-file=<file>`, `--assume-old=<file>`
    不重新生成的指定的<file>，即使这个目标的依赖文件新于它。

- `-p`, `--print-data-base`
    输出makefile中的所有数据，包括所有的规则和变量。这个参数会让一个简单的makefile都会输出一堆信息。如果你只是想输出信息而不想执行makefile，你可以使用“make -qp”命令。如果你想查看执行makefile前的预设变量和规则，你可以使用 “make –p –f /dev/null”。这个参数输出的信息会包含着你的makefile文件的文件名和行号，所以，用这个参数来调试你的 makefile会是很有用的，特别是当你的环境变量很复杂的时候。

- `-q`, `--question`
    不运行命令，也不输出。仅仅是检查所指定的目标是否需要更新。如果是0则说明要更新，如果是2则说明有错误发生。

- `-r`, `--no-builtin-rules`
    禁止make使用任何隐含规则。

- `-R`, `--no-builtin-variabes`
    禁止make使用任何作用于变量上的隐含规则。

- `-s`, `--silent`, `--quiet`
    在命令运行时不输出命令的输出。

- `-S`, `--no-keep-going`, `--stop`
    取消“-k”选项的作用。因为有些时候，make的选项是从环境变量“MAKEFLAGS”中继承下来的。所以你可以在命令行中使用这个参数来让环境变量中的“-k”选项失效。

- `-t`, `--touch`
    相当于UNIX的touch命令，只是把目标的修改日期变成最新的，也就是阻止生成目标的命令运行。

- `-v`, `--version`
    输出make程序的版本、版权等关于make的信息。

- `-w`, `--print-directory`
    输出运行makefile之前和之后的信息。这个参数对于跟踪嵌套式调用make时很有用。

- `--no-print-directory`
    禁止“-w”选项。

- `-W <file>`, `--what-if=<file>`, `--new-file=<file>`, `--assume-file=<file>`
    假定目标<file>;需要更新，如果和“-n”选项使用，那么这个参数会输出该目标更新时的运行动作。如果没有“-n”那么就像运行UNIX的“touch”命令一样，使得<file>;的修改时间为当前时间。

- `--warn-undefined-variables`
    只要make发现有未定义的变量，那么就输出警告信息。

## 九、隐含规则
### 1. 使用隐含规则
如果需要使用隐含规则生成所需目标，则不用写出这个目标的规则，make会自动推导产生这个目标的规则和命令。如果make可以自动推导生成这个目标的规则和命令，那么该行为就是隐含规则的自动推导。

make会在自己的“隐含规则”库中寻找可以用的规则，如果找到，那么就会使用。如果找不到，那么就会报错。

```makefile
foo : foo.o bar.o
    cc -o foo.o bar.o $(CFLAGS) $(LDFLAGS)
```
上例中make会自动推导 `foo.o` 和 `bar.o` 这两个目标的依赖目标与生成命令。make调用的隐含规则是，将 `.o` 目标的依赖文件置为 `.c`，并使用 `cc -c $(CFLAGS) foo.c` 生成 `foo.o` 的目标。

当然，如果为 `.o` 文件书写了自己的规则，那么make就不会自动推导并调用隐含规则，而是按照写好的规则执行。

在make的“隐含规则库”中，每一条隐含规则都在库中有其顺序，越靠前的则是越被经常使用的，所以，这会导致有些时候即使显示地指定了目标依赖，make也不会管。

```makefile
foo.o : foo.p
```
依赖文件 `foo.p` （Pascal程序的源文件）有可能变得没有意义。如果目录下存在了 `foo.c` 文件，那么我们的隐含规则一样会生效，并会通过 `foo.c` 调用C的编译器生成 `foo.o` 文件。因为，在隐含规则中，Pascal的规则出现在C的规则之后，所以，make找到可以生成 `foo.o` 的C的规则就不再寻找下一条规则了。如果不希望任何隐含规则推导，那么，就不要只写出“依赖规则”，而不写命令。

### 2. 隐含规则一览
如果不明确地写下规则，那么，make就会在这些规则中寻找所需要规则和命令。当然，我们也可以使用make的参数 `-r` 或 `--no-builtin-rules` 选项来取消所有的预设置的隐含规则。

当然，即使指定了 `-r` 参数，某些隐含规则依旧会生效，因为许多隐含规则使用了“**后缀规则**”进行定义。所以，只要隐含规则中有 “后缀列表”（也就一系统定义在目标 `.SUFFIXES` 的依赖目标），那么隐含规则就会生效。默认的后缀列表是：.out, .a, .ln, .o, .c, .cc, .C, .p, .f, .F, .r, .y, .l, .s, .S, .mod, .sym, .def, .h, .info, .dvi, .tex, .texinfo, .texi, .txinfo, .w, .ch .web, .sh, .elc, .el。

以下为常用的隐含规则：
1. 编译C程序的隐含规则。
    `<n>.o` 的目标的依赖目标会自动推导为 `<n>.c`，并且其生成命令是 `$(CC) -c $(CPPFLAGS) $(CFLAGS)`

2. 编译C++程序的隐含规则：
    `<n>.o` 的目标的依赖目标会自动推导为 `<n>.cc` 或 `<n>.cpp` 或是 `<n>.C`，并且其生成命令是 `$(CXX) –c $(CPPFLAGS) $(CXXFLAGS)`。

3. 编译Pascal程序的隐含规则：
    `<n>.o` 的目标的依赖目标会自动推导为 `<n>.p` ，并且其生成命令是 `$(PC) -c $(PFLAGS)`。

4. 编译Fortan/Ratfor程序的隐含规则：
    `<n>.o` 的目标依赖目标会自动推导为 `<n>.r` 或 `<n>.F` 或 `<n>.f`，并且命令是：
    - `.f`: `$(FC) –c  $(FFLAGS)`
    - `.F`: `$(FC) –c  $(FFLAGS) $(CPPFLAGS)`
    - `.r`: `$(FC) –c  $(FFLAGS) $(RFLAGS)`

5. 预处理Fortan/Ratfor程序的隐含规则：
    `<n>.f` 的目标依赖会自动推导为 `<n>.r` 或 `<n>.F`。这个规则只是转换Ratfor或有预处理的Fortan程序到一个标准的Fortan程序。其使用的命令是：
    - `.F`: `$(FC) –F $(CPPFLAGS) $(FFLAGS)`
    - `.r`: `$(FC) –F $(FFLAGS) $(RFLAGS)`

6. 编译Modula-2程序的隐含规则：
    `<n>.sym` 的目标的依赖目标会自动推导为 `<n>.def`，并且其生成命令是： `$(M2C) $(M2FLAGS) $(DEFFLAGS)`。 `<n>.o` 的目标的依赖目标会自动推导为 `<n>.mod`，并且其生成命令是：`$(M2C) $(M2FLAGS) $(MODFLAGS)`。

7. 汇编和汇编预处理的隐含规则
    `<n>.o` 的目标的依赖目标会自动推导为 `<n>.s` ，默认使用编译器 as ，并且其生成命令是 `$ (AS) $(ASFLAGS)` 。 `<n>.s` 的目标的依赖目标会自动推导为 `<n>.S` ，默认使用C预编译器 `cpp` ，并且其生成命令是 `$(CPP) $(CPPFLAGS)`。

8. 链接Object文件的隐含规则。
    `<n>` 目标依赖于 `<n>.o` ，通过运行C的编译器来运行链接程序生成（一般是 `ld` ），其生成命令是 `$(CC) $(LDFLAGS) <n>.o $(LOADLIBES) $(LDLIBS)`。这个规则对于只有一个源文件的工程有效，同时也对多个Object文件（由不同的源文件生成）的也有效。

    对于如下规则：
    ```makefile
    x : y.o z.o
    ```
    当 `x.c`、`y.c` 和 `z.c` 都存在是，隐含规则将执行如下命令：
    ```makefile
    cc -c x.c -o x.o
    cc -c y.c -o y.o
    cc -c z.c -o z.o
    cc x.o y.o z.o -o x
    rm -f x.o
    rm -f y.o
    rm -f z.o
    ```
    如果没有一个源文件（如上例中的x.c）和目标名字（如上例中的x）相关联，那么，最好写出自己的生成规则，不然，隐含规则会报错。

9. Yacc C程序时的隐含规则：
    `<n>.c` 的依赖文件被自动推导为 `n.y` （Yacc生成的文件），其生成命令是 `$(YACC) $(YFLAGS)`。Yacc是一个语法分析器。

10. Lex C程序时的隐含规则：
    `<n>.c` 的依赖文件被自动推导为 `n.l` （Lex生成的文件），其生成命令是 `$(LEX) $(LFLAGS)`。

11. Lex Ratfor程序时的隐含规则。
    `<n>.r` 的依赖文件被自动推导为 `n.l` （Lex生成的文件），其生成命令是 `$(LEX) $(LFLAGS)`。

12. 从C程序、Yacc文件或Lex文件创建Lint库的隐含规则。
    `<n>.ln` （lint生成的文件）的依赖文件被自动推导为 `n.c`，其生成命令是 `$(LINT) $(LINTFLAGS) $(CPPFLAGS) -i`。对于 `<n>.y` 和 `<n>.l` 也是同样的规则。

### 3. 隐含规则使用变量
由上述可知，隐含规则中的命令，基本上都使用了一些预先设置的变量，因此可以在makefile中改变这些变量的值，或在make命令行中传入这些值，或在环境变量中设置这些值，从而对隐含规则起作用。

可以把隐含规则中使用的变量分成两种：一种是命令相关的，如 `CC` ；一种是参数相的关，如 `CFLAGS` 。下面是所有隐含规则中会用到的变量：

#### (1) 关于命令的变量
- `AR`: 函数库打包程序。默认命令是 `ar`
- `AS`: 汇编语言编译程序。默认命令是 `as`
- `CC`: C语言编译程序。默认命令是 `cc`
- `CXX`: C++语言编译程序。默认命令是 `g++`
- `CO`: 从RCS文件中扩展文件程序。默认命令是 `co`
- `CPP`: C程序的预处理器（输出是标准输出设备）。默认命令是 `$(CC) –E`
- `FC`: Fortran 和 Ratfor 的编译器和预处理程序。默认命令是 `f77`
- `GET`: 从SCCS文件中扩展文件的程序。默认命令是 `get`
- `LEX`: Lex方法分析器程序（针对于C或Ratfor）。默认命令是 `lex`
- `PC`: Pascal语言编译程序。默认命令是 `pc`
- `YACC`: Yacc文法分析器（针对于C程序）。默认命令是 `yacc`
- `YACCR`: Yacc文法分析器（针对于Ratfor程序）。默认命令是 `yacc –r`
- `MAKEINFO`: 转换Texinfo源文件（.texi）到Info文件程序。默认命令是 `makeinfo`
- `TEX`: 从TeX源文件创建TeX DVI文件的程序。默认命令是 `tex`
- `TEXI2DVI`: 从Texinfo源文件创建军TeX DVI 文件的程序。默认命令是 `texi2dvi`
- `WEAVE`: 转换Web到TeX的程序。默认命令是 `weave`
- `CWEAVE`: 转换C Web 到 TeX的程序。默认命令是 `cweave`
- `TANGLE`: 转换Web到Pascal语言的程序。默认命令是 `tangle`
- `CTANGLE`: 转换C Web 到 C。默认命令是 `ctangle`
- `RM`: 删除文件命令。默认命令是 `rm –f`

#### (2) 关于命令参数的变量
下面的这些变量都是相关上面的命令的参数。如果没有指明其默认值，那么其默认值都是空。

- `ARFLAGS`: 函数库打包程序AR命令的参数。默认值是 `rv`
- `ASFLAGS`: 汇编语言编译器参数。（当明显地调用 `.s` 或 `.S` 文件时）
- `CFLAGS`: C语言编译器参数。
- `CXXFLAGS`: C++语言编译器参数。
- `COFLAGS`: RCS命令参数。
- `CPPFLAGS`: C预处理器参数。（C和Fortran编译器也会用到）。
- `FFLAGS`: Fortran语言编译器参数。
- `GFLAGS`: SCCS “get”程序参数。
- `LDFLAGS`: 链接器参数。（如：`ld` ）
- `LFLAGS`: Lex文法分析器参数。
- `PFLAGS`: Pascal语言编译器参数。
- `RFLAGS`: Ratfor 程序的Fortran编译器参数。
- `YFLAGS`: Yacc文法分析器参数。

### 4. 隐含规则链
有些时候，一个目标可能被一系列的隐含规则所作用。例如，一个 `.o` 的文件生成，可能会是先由Yacc的 `.y` 文件生成 `.c`，然后再被C的编译器生成。将这一系列的隐含规则叫做“隐含规则链”。

在上面的例子中，如果文件 `.c` 存在，那么就直接调用C的编译器的隐含规则，如果没有 `.c` 文件，但有一个 `.y` 文件，那么Yacc的隐含规则会被调用，生成 `.c` 文件，然后，再调用C编译的隐含规则最终由 `.c` 生成 `.o` 文件，达到目标。将这种 `.c` 文件称作中间目标。

make会努力自动推导生成目标的一切方法，不管中间目标有多少，其都会执着地把所有的隐含规则和所书写的规则全部合起来分析，努力达到目标。

在默认情况下，对于中间目标，它和一般的目标有两个地方所不同：第一个不同是除非中间的目标不存在，才会引发中间规则。第二个不同的是，只要目标成功产生，那么，产生最终目标过程中，所产生的中间目标文件会被以 `rm -f` 删除。

通常，一个被makefile指定成目标或是依赖目标的文件不能被当作中介。然而，可以明显地说明一个文件或是目标是中间目标，你可以使用伪目标 `.INTERMEDIATE` 来强制声明。（如： `.INTERMEDIATE : mid` ）

也可以阻止make自动删除中间目标，要做到这一点，可以使用伪目标 `.SECONDARY` 来强制声明（如： `.SECONDARY : sec` ）。还可以把目标以模式的方式来指定（如： `%.o` ）成伪目标 `.PRECIOUS` 的依赖目标，以保存被隐含规则所生成的中间文件。

在“隐含规则链”中，禁止同一个目标出现两次或两次以上，这样一来，就可防止在make自动推导时出现无限递归的情况。

make会优化一些特殊的隐含规则，而不生成中间文件。如，从文件 `foo.c` 生成目标程序 `foo`，按道理，make会编译生成中间文件 `foo.o`，然后链接成 `foo`，但在实际情况下，这一动作可以被一条 `cc` 的命令完成（ `cc –o foo foo.c` ），于是优化过的规则就不会生成中间文件。

### 5. 定义模式规则
可以使用模式规则来定义一个隐含规则。模式规则类似一般的规则，只是在规则中，目标的定义需要有 `%` 字符。`%` 表示一个或多个任意字符，依赖目标中使用，其取值取决于其其目标。

#### (1) 模式规则介绍
模式规则中，至少在规则的目标定义中要包含 `%`，否则为一般的规则。目标中的 `%` 定义表示对文件名的匹配，`%` 表示长度任意的非空字符串。

如果 `%` 定义在目标中，则依赖中的 `%` 的值决定了目标中 `%` 的值。

一旦依赖目标中的 `%` 模式被确定，那么，make会被要求去匹配当前目录下所有的文件名，一旦找到，make就会执行规则下的命令，所以，在模式规则中，目标可能会是多个的，如果有模式匹配出多个目标，make就会产生所有的模式目标，此时，make关心的是依赖的文件名和生成目标的命令这两件事。

#### (2) 自动化变量
- `$@`: 表示规则中的目标文件集。在模式规则中，如果有多个目标，那么 `$@` 就是匹配与目标中模式定义的集合
- `$%`: 仅当目标是函数库文件中，表示规则中的目标成员名。例如，如果一个目标是 `foo.a(bar.o)` ，那么， `$%` 就是 `bar.o` ， `$@` 就是 `foo.a` 。如果目标不是函数库文件（Unix下是 `.a` ，Windows下是 `.lib` ），那么，其值为空。
- `$<`: 依赖目标中的第一个目标名字。如果依赖目标是以模式定义的，则 `$<` 将是符合模式的一系列的文件集。
- `$?`: 所有比目标新的依赖目标的集合。以空格分隔。
- `$^`: 所有的依赖目标的集合。以空格分隔。如果在依赖目标中有多个重复的，那么这个变量会去除重复的依赖目标，只保留一份。
- `$+`: 这个变量很像 `$^` ，也是所有依赖目标的集合。只是它不去除重复的依赖目标。
- `$*`: 这个变量表示目标模式中 `%` 及其之前的部分，对于构造有关联的文件名是比较有效的。如果目标是 `dir/a.foo.b`，并且目标的模式是 `a.%.b`，那么，`$*` 的值就是 `dir/foo`。如果目标中没有模式的定义，那么 `$*` 也就不能被推导出，但是，如果目标文件的后缀是make所识别的，那么 `$*` 就是除了后缀的那一部分。

- `$?`: 表示所有“比目标文件新”的依赖文件列表（只包含已更新的依赖）。

#### (3) 模式匹配
在定义好的模式中，将 `%` 所匹配内容称为“**茎**”。当一个模式匹配包含有斜杠的文件时，在进行模式匹配时，目录部分首先被移开，然后进行匹配，成功后再将目录移回。

例如有一个模式 `e%t`，文件 `src/eat` 匹配于该模式，于是 `src/a` 就是其“茎”，如果这个模式定义在依赖目标中，而被依赖于这个模式的目标中又有个模式 `c%r` ，那么，目标就是 `src/car`。

#### (4) 重载内建隐含规则
make允许重载内建的隐含规则，例如可以重新构造和内建规则不同的命令。也可以取消内建的隐含规则，只需要不在后面写命令即可，如：
```makefile
%.o : %.s
```
同样，也可以重新定义一个全新的隐含规则，其在隐含规则中的位置取决于该规则的位置。朝前的位置就靠前。

### 6. 老式风格的后缀规则
后缀规则是一个比较老式的定义隐含规则的方法。后缀规则会被模式规则逐步地取代。因为模式规则更强更清晰。所有的后缀规则在Makefile被载入内存时，会被转换成模式规则。为了和老版本的Makefile兼容，GNU make同样兼容于这些东西。后缀规则有两种方式：“双后缀”和“单后缀”。

双后缀规则定义了一对后缀：目标文件的后缀和依赖目标（源文件）的后缀。如 `.c.o` 相当于 `%o : %c`。单后缀规则只定义一个后缀，也就是源文件的后缀。如 `.c` 相当于 `% : %.c`。

后缀规则中所定义的后缀应该是make所认识的，如果一个后缀是make所认识的，那么这个规则就是单后缀规则，而如果两个连在一起的后缀都被make所认识，那就是双后缀规则。

```makefile
.c.o:
    $(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $<
```

后缀规则不允许任何的依赖文件，如果有依赖文件的话，那就不是后缀规则，那些后缀统统被认为是文件名。

后缀规则中，如果没有命令，那是毫无意义的。因为它也不会移去内建的隐含规则。而要让make知道一些特定的后缀，我们可以使用伪目标 `.SUFFIXES` 来定义或是删除，如：
```makefile
.SUFFIXES : .hack .win
```
上例把后缀 `.hack` 和 `.win` 加入后缀列表中的末尾。

```makefile
.SUFFIXES : # 删除默认后缀
.SUFFIXES : .hack .win # 定义所需后缀
```
make的参数 `-r` 或 `-no-builtin-rules` 也会使用得默认的后缀列表为空。而变量 `SUFFIXE` 被用来定义默认的后缀列表，可以使用 `.SUFFIXES` 改变后缀列表，但是请不要改变变量 `SUFFIXE` 的值。

## 十、使用make更新函数库文件
函数库文件也就是对Object文件（程序编译的中间文件）的打包文件。在Unix下，一般是由命令 `ar` 来完成打包工作。

### 1. 函数库文件的成员
一个函数库文件由多个文件组成，可以使用如下格式制动函数库文件及其组成：
```makefile
archive(member)
```
这并非一个命令，而是一个目标和依赖的定义。一般来说，这种用法基本上就是为了 `ar` 命令服务。例如：
```makefile
foolib(hack.o) : hack.o
    ar cr foolib hack.o
```
如果要指定多个member，则需要以空格分开，如：
```makefile
foolib(hack.o kludge.o)
```
此外可以使用文件通配符进行定义。

### 2. 函数库成员的隐含规则
当make搜索一个目标的隐含规则时，一个特殊的特性是，如果这个目标是 `a(m)` 形式的，其会把目标变成 `(m)`。于是，如果我们的成员是 `%.o` 的模式定义，并且如果我们使用 `make foo.a(bar.o)` 的形式调用Makefile时，隐含规则会去找 `bar.o` 的规则，如果没有定义 `bar.o` 的规则，那么内建隐含规则生效，make会去找 `bar.c` 文件来生成 `bar.o` ，如果找得到的话，make执行的命令大致如下:
```makefile
cc -c bar.c -o bar.o
ar r foo.a bar.o
rm -f bar.o
```

函数库文件支持后缀规则和隐含规则来生成函数库打包文件。

```makefile
.c.a:
    $(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $*.o
    $(AR) r $@ $*.o
    $(RM) $*.o
```
其等价于：
```makefile
(%.o) : %.c
    $(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $*.o
    $(AR) r $@ $*.o
    $(RM) $*.o
```

### 3. 注意事项
在进行函数库打包文件生成时，请小心使用make的并行机制（ `-j` 参数）。如果多个 `ar` 命令在同一时间运行在同一个函数库打包文件上，就很有可以损坏这个函数库文件。所以，在make未来的版本中，应该提供一种机制来避免并行操作发生在函数打包文件上。

但就目前而言，你还是应该不要尽量不要使用 `-j` 参数。