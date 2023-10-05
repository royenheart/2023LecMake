#!/bin/bash

set -x

# libxxx.so - 动态库
# libxxx.a - 静态库
# gcc、clang/llvm 工具链

# gcc -E 只进行预处理
# gcc -S 只进行前端+中端生成中间代码（汇编形式）
# gcc -c 前端+中端+后端，通过汇编器将中间代码（汇编形式）编译成目标代码，但不进行链接
# gcc -o <file> 将结果写至 file 文件
# gcc -g 在生成的代码中加入调试信息
# gcc -Wa,<options> 传递汇编器选项
# gcc -Wp,<options> 传递预处理选项
# gcc -Wl,<options> 传递链接选项
# gcc -H 打印出文件使用的头文件名称（深度遍历）
# gcc -include <filename> 指定使用的头文件
# gcc -I <dirname> 指定头文件搜索使用的目录
# gcc -L 指定链接库文件使用的搜索目录
# gcc -lxxx 链接 xxx 库

# 其他一些相关命令
# strace, ldd, readelf, gdb, perf
# strace: linux syscall tracer (linux系统调用追踪器)
# strace -s 8192 -e execve -f -- <command> 2>&1 | tee ./debug.log 追踪程序的运行情况，对于二进制可执行文件的调试（主要在于系统调用）有一定的用处，用户态还是多学会使用 gdb 和 perf
# readelf -d xxx 查看可执行文件的动态库部分信息 （dynamic section）

m1D="out/m1"
m2D="out/m2"
m3D="out/m3"
m4D="out/m4"
m5D="out/m5"

mkdir -p ${m1D} ${m2D} ${m3D} ${m4D} ${m5D}

function parse_params() {
    if [[ $# -eq 0 ]]; then
        echo "./compile.sh clean    - clean all targets"
        echo "             m1       - make m1" 
        echo "             m2       - make m2" 
        echo "             m3       - make m3" 
        echo "             m4       - make m4" 
        echo "             m5       - make m5" 
        exit -1
    fi
    while [[ $# -ne 0 ]]; do
        case $1 in
            "clean")
                clean
                echo "make clean"
                shift
                ;;
            "m1")
                m1
                echo "make m1"
                shift
                ;;
            "m2")
                m2
                echo "make m2"
                shift
                ;;
            "m3")
                m3
                echo "make m3"
                shift
                ;;
            "m4")
                m4
                echo "make m4"
                shift
                ;;
            "m5")
                m5
                echo "make m5"
                shift
                ;;
            *)
                echo "$1 target not defined"
                shift
                ;;
        esac
    done
}

function clean() {
    rm -f ${m1D}/* ${m2D}/* ${m3D}/* ${m4D}/* ${m5D}/* 
}

function m1() {
    # 先全部编译成目标文件，最后进行链接，不使用动态、静态库
    g++ main.cpp -o ${m1D}/main.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ particle.cpp -o ${m1D}/particle.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c 
    g++ v3.cpp -o ${m1D}/v3.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ ${m1D}/main.o ${m1D}/particle.o ${m1D}/v3.o -o ${m1D}/main
}

function m2() {
    # statically linked，对 particle 和 v3 编译成动态库
    # 直接生成动态库，而不是先编译成目标文件再生成动态库
    # 但这样会导致动态库查找直接根据写进去的路径，跟编译时所处的目录有关
    # 在不同路径下会出错
    g++ main.cpp -o ${m2D}/main.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c 
    g++ particle.cpp -o ${m2D}/libparticle.so -shared -fPIC -g -ggdb -O0 -std=c++17 -Wall -march=native 
    g++ v3.cpp -o ${m2D}/libv3.so -shared -fPIC -g -ggdb -O0 -std=c++17 -Wall -march=native
    g++ ${m2D}/main.o ${m2D}/libparticle.so ${m2D}/libv3.so -o ${m2D}/main
}

function m3() {
    # 先全部编译成目标文件
    g++ main.cpp -o ${m3D}/main.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    # -fPIC -shared 在生成目标文件/生成动态库时都需使用
    # 在生成最终可执行目标文件时不需要
    g++ particle.cpp -o ${m3D}/particle.o -fPIC -shared -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ v3.cpp -o ${m3D}/v3.o -fPIC -shared -g -ggdb -O0 -std=c++17 -Wall -march=native -c 
    # 将目标文件生成动态库
    g++ ${m3D}/v3.o -o ${m3D}/libv3.so -fPIC -shared
    # rpath/rpath-link 不能单独使用，还是需要和 -L 一起使用
    # rpath 直接在最终生成的文件头中记录动态库文件位置（直接记录给定参数，因此如果用的是相对路径很容易导致动态库无法找到），用于程序运行时
    # rpath-link 在编译时，用于找依赖的动态库找不到其对应依赖库时，指定存放路径
    # rpath 优先级低于 LD_LIBRARY_PATH/LD_PRELOAD，因此可以被这两个环境变量覆盖
    g++ ${m3D}/particle.o -o ${m3D}/libparticle_rpath-link.so -fPIC -shared -Wl,-L${m3D} -Wl,-rpath-link=${m3D} -lv3
    g++ ${m3D}/particle.o -o ${m3D}/libparticle_rpath.so -fPIC -shared -Wl,-L${m3D} -Wl,-rpath=${m3D} -lv3
    g++ ${m3D}/particle.o -o ${m3D}/libparticle.so -fPIC -shared -Wl,-L${m3D} -lv3
    g++ ${m3D}/main.o -o ${m3D}/main_rpath-link -Wl,-L${m3D} -Wl,-rpath-link=${m3D} -lparticle_rpath-link -lv3 
    g++ ${m3D}/main.o -o ${m3D}/main_rpath -Wl,-L${m3D} -Wl,-rpath=${m3D} -lparticle_rpath -lv3 
    # 最后链接到一起
    g++ ${m3D}/main.o -o ${m3D}/main -Wl,-L${m3D} -lparticle -lv3 
}

function m4() {
    # 先生成目标文件
    g++ main.cpp -o ${m4D}/main.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ particle.cpp -o ${m4D}/particle.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ v3.cpp -o ${m4D}/v3.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c 
    # 将目标文件组合到一起，即生成静态库，静态库生成使用 ar 
    ar crv ${m4D}/libv3.a ${m4D}/v3.o
    ar crv ${m4D}/libparticle.a ${m4D}/particle.o
    ranlib ${m4D}/libv3.a
    ranlib ${m4D}/libparticle.a
    # 使用 -static ，全部进行静态链接，则生成的文件将不是动态可执行文件
    # 会对项目所有的依赖库都尝试去搜索 libname.a 的静态库文件，包括编译器自带的库（libstdc++等），除了 Linux Kernel 外 
    g++ ${m4D}/main.o -o ${m4D}/main -static -Wl,-L${m4D} -lparticle -lv3 
    # 不使用 -static，-l 也会去搜索（先搜索动态库，再搜索静态库）动态/静态库，先搜索到的使用，故libstdc++ 等会先使用动态库
    g++ ${m4D}/main.o -o ${m4D}/main_1 -Wl,-L${m4D} -lparticle -lv3 
    # g++ ${m4D}/main.o -o ${m4D}/main_1 -shared -Wl,-L${m4D} -lparticle -lv3 
    # 上面的指令编译失败
    # 总结：都使用 -l.. 进行链接，-static 参数强制使用静态库，-shared 强制使用动态库
}

function m5() {
    g++ mixed_main.cpp -o ${m5D}/mixed_main.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ mixed_a.cpp -o ${m5D}/mixed_a.o -fPIC -shared -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    g++ mixed_b.cpp -o ${m5D}/mixed_b.o -g -ggdb -O0 -std=c++17 -Wall -march=native -c
    # 生成动态库和静态库
    g++ ${m5D}/mixed_a.o -o ${m5D}/libmixed_a.so -fPIC -shared
    ar crv ${m5D}/libmixed_b.a ${m5D}/mixed_b.o
    ranlib ${m5D}/libmixed_b.a
    # 可以编译，mixed_a 使用动态库，mixed_b 使用静态库
    g++ ${m5D}/mixed_main.o -o ${m5D}/mixed_main -Wl,-L${m5D} -lmixed_a -lmixed_b
    # 下面两个都无法通过
    # g++ ${m5D}/mixed_main.o -o ${m5D}/mixed_main -static -Wl,-L${m5D} -lmixed_a -lmixed_b 
    # g++ ${m5D}/mixed_main.o -o ${m5D}/mixed_main -shared -Wl,-L${m5D} -lmixed_a -lmixed_b 
    # 另外两种部分指定静态库的编译方式，可以编译通过
    # Bstatic 后的库全部搜索静态库
    # -l:库名称（lib<name>.a）也可以直接使用静态库（同样需要指定搜索位置）
    g++ ${m5D}/mixed_main.o -o ${m5D}/mixed_main_v1 -Wl,-L${m5D} -lmixed_a -Bstatic -lmixed_b 
    g++ ${m5D}/mixed_main.o -o ${m5D}/mixed_main_v2 -Wl,-L${m5D} -lmixed_a -l:libmixed_b.a 
}

parse_params $@