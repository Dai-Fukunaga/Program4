target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

define dso_local i32 @main() {
    %t1 = alloca i32
    store i32 0, i32 *%t1
    %t2 = add i32 1, 2
    store i32 %t2, i32 *%t1
    %t3 = load i32, i32 *%t1
    %t4 = add i32 %t3, 3
    %t5 = alloca i32
    store i32 %t4, i32 *%t5
    %t6 = alloca i32
    %t7 = alloca i32
    store i32 4, i32 *%t7
    %t8 = add i32 4, 5
    store i32 %t8, i32 *%t6
    %t9 = load i32, i32 *%t1
    %t10 = add i32 %t9, 6
    store i32 %t10, i32 *%t5
    %t11 = load i32, i32 *%t1
    %t12 = add i32 2, %t11
    %t13 = alloca i32
    store i32 %t12, i32 *%t13
    %t14 = load i32, i32 *%t5
    ret i32 %t14
    ret i32 0;
}
