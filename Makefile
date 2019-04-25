workstation-debug:
	g++ -O2 -march=native src/main.cpp -Ddebug -o bin/a -lOpenCL

workstation:
	g++ -O2 -march=native src/main.cpp -o bin/a -lOpenCL

vlab:
	g++ -std=c++11 -O2 -march=native src/main.cpp -o bin/a `aocl compile-config` `aocl link-config`

