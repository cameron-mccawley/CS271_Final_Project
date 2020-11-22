# 2.3 Insights

## 2.3.1 C
### Variable Arguments
1. **How does C support variable arguments?**\
C supports variable arguments by storing local variables on the stack.  When a function is called that uses variable arguments in a 64 bit binary, it reads from arguments passed by registers.  What is interesting here is how when there are more than six arguments passed on the stack, rather than passing everything by registers, it uses both the registers and the stack to pass arguments, and the function that is being called can read from both and store them as local variables.  
So this, which shows a mix of passing variables and values:
```c++
int function(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j) {
    return a+c;
}

int main(){
    int a = 8;
    int b = 6;
    int c = 4;
    function(a, b, c, 1, 2, 3, 4, 5, 6, 7);
    return 0;
}
```
Becomes this, which clearly shows how both registers and the stack is used to pass variables:
```
function:
        push    rbp
        mov     rbp, rsp
        mov     DWORD PTR [rbp-4], edi			;Move all of the values passed onto the stack
        mov     DWORD PTR [rbp-8], esi
        mov     DWORD PTR [rbp-12], edx
        mov     DWORD PTR [rbp-16], ecx
        mov     DWORD PTR [rbp-20], r8d
        mov     DWORD PTR [rbp-24], r9d
        mov     edx, DWORD PTR [rbp-4]
        mov     eax, DWORD PTR [rbp-12]
        add     eax, edx
        pop     rbp
        ret
main:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     DWORD PTR [rbp-4], 8			;Create local variable a
        mov     DWORD PTR [rbp-8], 6			;Create local variable b
        mov     DWORD PTR [rbp-12], 4			;Create local variable c
        mov     edx, DWORD PTR [rbp-12]			;Passing variables by registers
        mov     esi, DWORD PTR [rbp-8]
        mov     eax, DWORD PTR [rbp-4]
        push    7								;Passing values by stack
        push    6
        push    5
        push    4
        mov     r9d, 3							;Passing values by registers
        mov     r8d, 2
        mov     ecx, 1
        mov     edi, eax
        call    function						;The function is called
        add     rsp, 32
        mov     eax, 0
        leave
        ret
```

2. **Who does the stack cleanup?**\
Stack cleanup is done at the end of a procedure and is added in during compile time.  It does this by adding to `rsp` the number of bytes that need to be cleaned up.
```
		push	2
		push	1
		call	function
		add		esp, 8							;Caller cleans up the stack
```

3. **What are the secrets of _va\_list_, _va\_start_, _va\_array_, and _va\_end_?**\
va_list seems to just make space for a bunch of bytes for local variables in the function its creating the list in. va_start initilizes the va_list to retrive additional argumetns in the `...`. It does this by setting up local variables and registers in a way that would allow for arguments passed into the function can be read off no matter how many are placed. va_arg retrives the next argument passed in by checking to see if the end of the argument list has been reached, and if it hasn't, it loads the next argument on the stack into the va_list. va_end didn't seem to actually have any assembly code linked to it.  The documentation states that the function is supposed to perform the appropriate actions so that a function can return normally, but this functionallity doesn't show up in the disassebled binary.
```c++
#include <stdarg.h>

int function(int num_args, ...){
    double sum = 0;
    va_list arguments;
    va_start(arguments, num_args);
    for ( int x = 0; x < num_args; x++ )        
    {
        va_arg ( arguments, double );			//Taking out the sum += so that assembly is more readable
    }

    va_end (arguments);
    return sum;
}

int main(){
    function(1, 2, 3);
}
```
```
function:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 120							;Make room for variables that could be passed (...)
        mov     DWORD PTR [rbp-228], edi
        mov     QWORD PTR [rbp-168], rsi
        mov     QWORD PTR [rbp-160], rdx
        mov     QWORD PTR [rbp-152], rcx
        mov     QWORD PTR [rbp-144], r8
        mov     QWORD PTR [rbp-136], r9
        test    al, al
        je      .L8
        movaps  XMMWORD PTR [rbp-128], xmm0
        movaps  XMMWORD PTR [rbp-112], xmm1
        movaps  XMMWORD PTR [rbp-96], xmm2
        movaps  XMMWORD PTR [rbp-80], xmm3
        movaps  XMMWORD PTR [rbp-64], xmm4
        movaps  XMMWORD PTR [rbp-48], xmm5
        movaps  XMMWORD PTR [rbp-32], xmm6
        movaps  XMMWORD PTR [rbp-16], xmm7
.L8:												;va_start is implemented in this block
        pxor    xmm0, xmm0
        movsd   QWORD PTR [rbp-192], xmm0
        mov     DWORD PTR [rbp-216], 8
        mov     DWORD PTR [rbp-212], 48	
        lea     rax, [rbp+16]
        mov     QWORD PTR [rbp-208], rax
        lea     rax, [rbp-176]
        mov     QWORD PTR [rbp-200], rax
        mov     DWORD PTR [rbp-180], 0
        jmp     .L3
.L6:												;Here we can see va_arg in both .L6 and .L4
        mov     eax, DWORD PTR [rbp-212]
        cmp     eax, 175
        ja      .L4
        mov     eax, DWORD PTR [rbp-212]
        add     eax, 16
        mov     DWORD PTR [rbp-212], eax
        jmp     .L5
.L4:
        mov     rax, QWORD PTR [rbp-208]
        add     rax, 8
        mov     QWORD PTR [rbp-208], rax
.L5:												;increment by 1 in for loop
        add     DWORD PTR [rbp-180], 1
.L3:
        mov     eax, DWORD PTR [rbp-180]
        cmp     eax, DWORD PTR [rbp-228]
        jl      .L6
        movsd   xmm0, QWORD PTR [rbp-192]
        cvttsd2si       eax, xmm0
        leave
        ret
main:
        push    rbp
        mov     rbp, rsp
        mov     edx, 3
        mov     esi, 2
        mov     edi, 1
        mov     eax, 0
        call    function							;Call function
        mov     eax, 0
        pop     rbp
        ret
```
So from this, it looks like va_start, va_arg, and va_end act as a way to query for the paramter list.  The va_arg macro translates the list into an actual argumetnt value, and then advances it to the next paramter in the list.	We also see that va_list is just a byte pointer, which va_start assigns it what to point to.  Not so secret anymore :)\

### Control Flows
1. **With only two branches, is the assembly similar between _if/else_ and _switch/case_?**\
For _if/else_:
```c++
int main(){
    int num = 0;

    if(num == 0){
        num += 1;
    }else{
        num -= 1;
    }

    return 0;
}
```
Gives us:
```
main:
        push    rbp
        mov     rbp, rsp
        mov     DWORD PTR [rbp-4], 0
        cmp     DWORD PTR [rbp-4], 0
        jne     .L2
        add     DWORD PTR [rbp-4], 1
        jmp     .L3
.L2:
        sub     DWORD PTR [rbp-4], 1
.L3:
        mov     eax, 0
        pop     rbp
        ret
```
For _switch/case_:
```c++
int main(){
    char grade = 'B';

      switch(grade) {
      case 'A' :
         printf("Excellent!\n" );
         break;
      case 'B' :
        printf("Woot!\n");
        break;
    default:
        break;
   }

    return 0;
}
```
```
.LC0:
        .string "Excellent!"
.LC1:
        .string "Woot!"
main:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     BYTE PTR [rbp-1], 66
        movsx   eax, BYTE PTR [rbp-1]
        cmp     eax, 65
        je      .L2
        cmp     eax, 66
        je      .L3
        jmp     .L5
.L2:
        mov     edi, OFFSET FLAT:.LC0
        call    puts
        jmp     .L5
.L3:
        mov     edi, OFFSET FLAT:.LC1
        call    puts
        nop
.L5:
        mov     eax, 0
        leave
        ret
```
With only two branches, the way these statements are compiled really are not that different at all.  They both cmp values and jump to the specific lable depending on the flags `cmp` set. Something I think is intersting is the way `default` is handled in the switch statement. It's basically exactly the same as what we have been coding by hand for a default jump back to the rest of the program, but here it's expicitly stated.\

2. **What about a big number of branches? Especially with obvious differences of integers in those _case_ statements, for example, _case 1:, case 22:, case 333:, ..._**\
It seems that for a big number of branches in switch statements, it seems to be much more optimal as it just has to compare a single value to a constant.  It acts almost like a lookup table, in which the lable that needs to be jumped to is only dependent on if the case matches the expression.  We can see this in the following code in C:
```c
int main(){
    int num = 8;
    int a;
    switch(num){
        case 1:
            a = 5;
            break;
        case 111:
            a = 4;
            break;
        case 1111:
            a = 2;
            break;
        case 333:
            a = 1;
            break;

    }
}
```
Which gets turned into this in assembly:
```
main:
        push    rbp
        mov     rbp, rsp
        mov     DWORD PTR [rbp-4], 8
        cmp     DWORD PTR [rbp-4], 1111
        je      .L2
        cmp     DWORD PTR [rbp-4], 1111
        jg      .L3
        cmp     DWORD PTR [rbp-4], 333
        je      .L4
        cmp     DWORD PTR [rbp-4], 333
        jg      .L3
        cmp     DWORD PTR [rbp-4], 1
        je      .L5
        cmp     DWORD PTR [rbp-4], 111
        je      .L6
        jmp     .L3
.L5:
        mov     DWORD PTR [rbp-8], 5
        jmp     .L3
.L6:
        mov     DWORD PTR [rbp-8], 4
        jmp     .L3
.L2:
        mov     DWORD PTR [rbp-8], 2
        jmp     .L3
.L4:
        mov     DWORD PTR [rbp-8], 1
        nop
.L3:
        mov     eax, 0
        pop     rbp
        ret
```
This is much different than how a bunch of if/else statements get compiled.  With if/else, we notice that the `cmp` are happening in each individual block, rather than all at once in a single lable.  This is because we arent comparing values to constants, and instead we are working with variables.  This makes if/else statements much more inefficient.
```c++
int main(){
    int a = 1;
    int b = 2;
    int c = 3;
    int d;

    if(a > b){
        d = 4;
    }else if(b >a ){
        d = 5;
    }else if(c == a){
        d = 6;
    }else if(c < a){
        d = 7;
    }
}
```
And in assembly:
```
main:
        push    rbp
        mov     rbp, rsp
        mov     DWORD PTR [rbp-4], 1
        mov     DWORD PTR [rbp-8], 2
        mov     DWORD PTR [rbp-12], 3
        mov     eax, DWORD PTR [rbp-4]
        cmp     eax, DWORD PTR [rbp-8]
        jle     .L2
        mov     DWORD PTR [rbp-16], 4
        jmp     .L3
.L2:
        mov     eax, DWORD PTR [rbp-8]
        cmp     eax, DWORD PTR [rbp-4]
        jle     .L4
        mov     DWORD PTR [rbp-16], 5
        jmp     .L3
.L4:
        mov     eax, DWORD PTR [rbp-12]
        cmp     eax, DWORD PTR [rbp-4]
        jne     .L5
        mov     DWORD PTR [rbp-16], 6
        jmp     .L3
.L5:
        mov     eax, DWORD PTR [rbp-12]
        cmp     eax, DWORD PTR [rbp-4]
        jge     .L3
        mov     DWORD PTR [rbp-16], 7
.L3:
        mov     eax, 0
        pop     rbp
        ret
```

## 2.3.2 C++
### Passing Parameters
1. **C++ supports passing parameters by values, pointers, and references. How are they different in ASM?**\

### C++ Object Model (Encapsulation Only)
1. **Life Cycle: Create an object on the stack. When is the constructor called? What about the destructor?**\

2. **Memory Layout: Inspecting the addresses of those class members, are the contiguous in memory when instantiated? Where are they located? Are those member variables and member functions far away from each other?**\

3. **This Pointer: Inspecting the assembly of a member function, is there an additional parameter? What about a static function defined in the class?**\

4. **Memory Layout: Create another object on the stack. Are these on-stack objects in a contiguous memory layout?**\

5. **Life Cycle: Create an object on the heap.  When is the constructor called? The destructor?**\

6. **Memory Layout: Create another object on the heap. Are these on-heap objects in a contiguous memory layout?**\

7. **Memory Layout: Are there more than one copy of member functions after so many objects have been created?**\

8. **Keywords: If we change _class_ to _struct_, does it make any difference in ASM?**\

### C++ Operators
1. **For the printing code, `std::cout << "Hello World!"`, what essentially is `<<`? An x86 instruction? What is `std::cout`? A constant?**\
The `<<` operator when decompiled is just a function.  More specifically, the function is an operator overload, which takes in both left and right values.  In the operator overload, we see that the string address is passed into `esi`, and the address of the exported function is placed in `edi`. 
```C++
#include <iostream>

int main(){
    std::cout << "Hello World!";
    return 0;
}
```
```
main:
        push    rbp
        mov     rbp, rsp
        mov     esi, OFFSET FLAT:.LC0
        mov     edi, OFFSET FLAT:_ZSt4cout
        call    std::basic_ostream<char, std::char_traits<char> >& std::operator<< <std::char_traits<char> >(std::basic_ostream<char, std::char_traits<char> >&, char const*)
        mov     eax, 0
        pop     rbp
        ret
```
## 2.3.3 ABIs
1. **Does it matter which languages were used in coding Win32 libraries, as long as we know the specifications, like the calling coventions, from MSDN?**\


