target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

define dso_local i32 @main() {
    %t1 = alloca i32
    %t2 = alloca float
    %t3 = sitofp i32 2 to float
    store float %t3, float *%t2
    %t4 = alloca i32
    store i32 3, i32 *%t4
    %t5 = load float, float *%t2
    %t6 = load i32, i32 *%t4
    %t7 = sitofp i32 %t6 to float
    %t8 = fdiv float %t5, %t7
    %t9 = sitofp i32 4 to float
    %t10 = fmul float %t8, %t9
    %t11 = fptosi float %t10 to i32
    store i32 %t11, i32 *%t1
    %t12 = load i32, i32 *%t1
    ret i32 %t12
    ret i32 0;
}
