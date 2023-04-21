target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

define dso_local i32 @main() {
    %t1 = alloca i32
    ret i32 0;
}

; Also, you will get below comments on your terminal
; 'i' was not declared
; cannot use % to float
; cannot declare the same variable
; left-hand-side of an assignment must be a variable
