target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

define dso_local i32 @main() {
    %t1 = sub i32 0, 1
    %t2 = sub i32 0, 3
    %t3 = sub i32 0, 6
    %t4 = mul i32 %t2, %t3
    %t5 = add i32 %t1, %t4
    %t6 = fneg float 0x40179999A0000000
    %t7 = sitofp i32 %t5 to float
    %t8 = fadd float %t7, %t6
    %t9 = sext i8 99 to i32
    %t10 = sub i32 0, %t9
    %t11 = sitofp i32 %t10 to float
    %t12 = fsub float %t8, %t11
    %t13 = sext i8 97 to i32
    %t14 = srem i32 %t13, 15
    %t15 = sitofp i32 %t14 to float
    %t16 = fadd float %t12, %t15
    %t17 = alloca i32
    %t18 = fptosi float %t16 to i32
    store i32 %t18, i32 *%t17
    %t19 = load i32, i32 *%t17
    ret i32 %t19
    ret i32 0;
}
