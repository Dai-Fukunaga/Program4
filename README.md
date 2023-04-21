# CS541 Program 4
"Program 4" is an assignment for CS541.

## Description
This program is for LLVM Code-Generator.

## Author
Dai Fukunaga

## Date
04/21/2023

## Get Started
### Requires
* Ubuntu 22.04.2 LTS
* bison (GNU Bison) 3.8.2
* flex 2.6.4
* Ubuntu LLVM version 14.0.0
* g++ (Ubuntu 11.3.0-1ubuntu1~22.04) 11.3.0
* GNU Make 4.3

### Executing Program
* Compile the codes
```bash
make
```

* Run the program without input files
```
./c2ll
```
This program reads standard input forever until `EOF`. Therefore, you have to type `Ctrl+D` at the end of the input.

* Run the program with an input file
```bash
./c2ll < input_file_path
```

* Make .ll file with an input file
```bash
./c2ll < input_file_path > output_file.ll
```

* Check the return value of a .ll file
```bash
lli output_file.ll
echo $?
```

* Delete the execute programs
```bash
make clean
```

## Test Cases
There are many test cases in the `tests` directory. <br>
For example, if you want to test a `01_calculate_in.txt` file, run like below.
```bash
./c2ll < ./tests/01_calculate_in.txt
```
You can see the expected result in a `01_calculate_out.ll` file.

## Design
The convert function converts the type so that the types match. <br>
I changed the order of the `enum class Type` in `type.h`. Because I want to make a convert function. DO NOT CHANGE the order of this enum.<br>
The value of the linux error code is an integer between 0 and 255. Therefore, if a value outside that range is returned, the remainder divided by 256 will be returned.

## Bugs
No bugs right now.

## References
No references right now.
