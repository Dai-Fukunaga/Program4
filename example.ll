target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Original code:  int x = 0; return x + 4;
define dso_local i32 @main() {
  %t1 = alloca i32
  store i32 2, i32 *%t1
  %t2 = load i32, i32 *%t1
  %t3 = add i32 4, %t2
  ret i32 %t3
  ret i32 0
}

