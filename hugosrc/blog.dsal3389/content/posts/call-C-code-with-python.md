---
title: "Call C Code With Python"
date: 2022-05-22T17:13:48+03:00
slug: call-c-code-with-python
type: posts
draft: false
categories:
  - python
  - C
tags:
  - python
  - C
---

### before you read, its good to know:
 * [shared C libraries]({{< relref "/posts/shared-c-libraries" >}})

---

sometimes we may want to call C functions from python, because python may be:
 * limiting
 * slow
 * wont have those functions
 * we dont want to rewrite those functions again in python

with `ctypes` we can import [shared C libraries]({{< relref "/posts/shared-c-libraries" >}}), this give us almost all libc functionality
(or any other shared library that we may want to load)

## how C and python handle the same data type
C and python are 2 different languages, so they handle the same data type differently, also python is a dynamiclly typed language,
while C is staticlly typed language, so we can't just directly pass arguments from python to C and vice versa, so before
passing the values to the C function, python does [Marshalling](https://en.wikipedia.org/wiki/Marshalling_(computer_science)) (in short, convert data from format A to format B)

(for this explanation let us assum that the C bytes values are correct)\
C stores data in the smalles unit possible, integer is just 4 bytes, character is 1 byte, string is a list of
characters that the end of the string defined by the null terminator '\0'

in python everything is an object, integer is object, string is object, float is object, even functions in reality
are objects, the length of the object in bytes can vary from system to system, but this is hidden from the python
programmer

so you see the problem?, python stores everything as objects, while C doesnt even have objects, only the "raw"
form of the value 

for that, before we pass some values to the C functions from python, we may need to specifiy what value we are passing,
so python can convert it to C data type structure

## import libc in python and use it

```py
import ctypes 


libc_name = "libc.so.6"
libc = ctypes.CDLL(libc_name)


def main():
    language = b"python"
    libc.printf(b"Hello world from %s (%S)\n", language, libc_name)


if __name__ == '__main__':
    main()
```

we imported the libc with `ctypes.CDLL` function by providing its name, we can also give
the absolute path to the shared library if we want to use some shared library that does not exists in `/etc/ld.so.conf`

[python3 document, how to use ctypes](https://docs.python.org/3/library/ctypes.html)

## create your own shared library, and call functions with python

project file structure
```
|-- main.py
`-- mylib
    `-- mylib.c
```

```c
// mylib.c
#include <stdio.h>


float my_func(int i, float f){
    printf("i=%d, f=%f\n", i, f);
    return (float) i + f;
}
```

function takes integer and float, print them to the scree, and combie them,
now lets compile our new lib to object file and then create the shared library \
(this can be done in one command, but for readability and understandability, we split it to 2 seperate commands)

```sh
> gcc -c -fpic mylib.c
> gcc -shared mylib.o -o libmylib.so
```

now we can import our lib with the `main.py` and use this function like so
```py
import os
import ctypes 


mylib = ctypes.CDLL(os.path.join('mylib', 'libmylib.so'))


def main():
    i = 3
    f = 0.5

    print(mylib.my_func(i, f))

if __name__ == '__main__':
    main()
```

if we run this python code we will get
```
> python3 main.py 
Traceback (most recent call last):
  File "/home/foo/main.py", line 15, in <module>
    main()
  File "/home/foo/main.py", line 12, in main
    print(mylib.my_func(i, f))
ctypes.ArgumentError: argument 2: <class 'TypeError'>: Don't know how to convert parameter 2
```

this is happend because python dont know to what to convert the float, we can see the error message
`Don't know how to convert parameter 2`, and parameter 2 is the float, so we need to tell python what float is this
```py
# ...
  mylib.my_func(i, ctypes.c_float(f))
```

```
> python3 main.py
i=3, f=0.500000
```