#!/bin/bash

marco () {
    pwd > ~/marco_location.txt
    echo "已保存当前目录至~/marco_location.txt"
}

polo () {
    if [ ! -f ~/marco_location.txt ]
    then
        echo "错误，未执行marco命令保存目录"
        return 1
    fi

    local save_dir=$(cat ~/marco_location.txt)

    if [ ! -d "$save_dir" ]; then
        echo "保存目录不存在"
        return 1
    fi

    cd "$save_dir"
}

clean_marco () {
    if [ -e ~/marco_location.txt ]
    then
        rm ~/marco_location.txt
        echo "~/marco_location.txt已清除"
    else
        echo "不存在~/marco_location.txt，可能已经被清除"
    fi
}