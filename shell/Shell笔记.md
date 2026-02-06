# Shell笔记
---
笔记参考教程为[The missing semester of your CS education](https://missing-semester-cn.github.io/)，仅仅是作为学习记录，未经允许不得转载。
## 主题1: The Shell
### 1. shell基础
shell是一个编程环境，具备变量、条件、循环和函数。在shell执行命令时，实际上时执行一段shell可以解释执行的简短代码。

shell基于空格对命令进行解析，然后执行第一个单词代表的程序，并将后续单词作为程序可访问的参数。例如：
```shell
lzl:~$ echo hello
hello
```
此处 `echo` 程序可将参数打印在终端上进行显示。

对于不是shell所了解的变成关键字，它会咨询*环境变量* `$PATH` ，它会列出当shell接到某条指令时，进行程序搜索的路径。 `$PATH` 中一系列目录由 `:` 进行分割。确定某个程序名代表的是哪个具体的程序，可以使用 `which` 程序。我们也可以绕过 `$PATH`，通过直接指定需要执行的程序的路径来执行该程序。示例如下：
```shell
lzl:~$ which echo
/bin/echo
lzl:~$ /bin/echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### 2. shell中导航
shell总路径时一组被分割的目录，在Linux中使用 `/` 分割，在Windows上是 `\` 。路径 `/` 代表系统的根目录，所有文件夹包含在这个路径下，Windows中每个盘有一个根目录（如 `C:\` ）。