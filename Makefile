# 推荐教程：[跟我一起写 Makefile 1.0](https://seisman.github.io/how-to-write-makefile/overview.html)

# 指定变量
# xxx := xxx
# 指定编译器

CC := gcc
CXX := g++

# .PHONY 表示岂不是一个生成的真实文件，而是 “伪目标”

.PHONY: all
all: main

# 依赖可以是具体文件名，也可以是设置的目标，make 自动解析编译顺序

main: main.o libv3 libparticle
	$(CXX) main.o -o main -Wl,-L. -lv3 -lparticle

main.o: main.cpp
	$(CXX) main.cpp -I. -c -std=c++17

libparticle: particle.cpp libv3
	$(CXX) particle.cpp -o particle.o -I. -c -fPIC -std=c++17 -shared -c
	$(CXX) particle.o -o libparticle.so -fPIC -shared -Wl,-L. -lv3

libv3: v3.cpp
	$(CXX) v3.cpp -o v3.o -I. -fPIC -std=c++17 -shared -c 
	$(CXX) v3.o -o libv3.so -fPIC -shared

# 大多 c/c++ 编译器支持 -M 选项，可以自动寻找源文件中包含的头文件，并根据此生成依赖关系
# 因此 Make 可以借此来自动生成依赖关系

# make 提供检测文件是否进行更改，比如有一个目标 main，当这个对应的文件进行了更改，又执行了 make main，那么会重新执行一次这个目标中的 commands
# 但若是没有更改，又再次执行了 make main，就会认为 up to date，就不会执行
# 加上伪目标表示这不是一个真实文件，就不会去检测文件是否被更改

.PHONY: clean
clean:
	rm -f libv3.so libparticle.so v3.o particle.o main.o main