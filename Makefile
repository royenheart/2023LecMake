# 这是注释

# 包管理器安装：apt install make
# 或者直接安装 bulild-essential：apt install build-essential
# build-essential 中包含 GNU/g++ 编译器，GNU debugger 以及一些其他编译常用的库，包括：make, dpkg-dev 等
#
# Makefile 核心为 target（目标）
# 基本格式（使用 tab 缩进）
# 	name: dependencies
# 		commands
# 
# 构建某个具体 target，使用：
# 	make target
# 默认当前目录查找 Makefile 文件，可以使用 -C <dir> 选项来先切换到指定目录再执行，适合 Makefile 不放在当前目录

hello: 
	$(CXX) -o hello hello.cpp
	echo "make hello compeleted"