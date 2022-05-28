---
title: "Shared C Libraries"
date: 2022-05-22T17:19:27+03:00
slug: shared-c-libraries
type: posts
draft: false
categories:
  - C
tags:
  - C
---

## quick access to some sections
* [using shared libraries](#using-shared-libraries)
* [write your own shared library](#write-your-own-shared-library)

---

when we compile C code, we using shared libraries all the time without knowing it, to see what shared libraries some executable is using we can use the _ldd_ command like so

```sh
> ldd <executable>
> ldd a.out
	linux-vdso.so.1 (0x...)
	libc.so.6 => /usr/lib/libc.so.6 (0x...)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x...)
```

## but what is a shared library?
a shared library is exactly how it sounds like, its a library that is shared between multiple programs,
the library is loaded once into memory (_as a read only block_) and its shared between process that need to use it, there are couple of _advantages_:

* executables are smaller size because the library is dynamiclly linked to the program and its not part of the executable
* if we need to update something in the library we dont need to recompile the whole program, only the library and it will effect all programs that are using it
* common libraries are loaded once into memory and shared between many process who need it

## how this black magic is done?
the _dynamic linker_ is the one who is responsible to know where the required shared libraries sit, and link your program with them dynamiclly when your program is loaded into memory

## where the shared libraries are stored?
there are standard that tell us where to store them ([look here](https://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html#AEN62)) but we dont need to conver it right now,
the _dynamic linker_ read the contents of _/etc/ld.so.conf_, this file contain the path that tells the _dynamic linker_, where to search for the required shared library, most of the time it will be stored in

* _/usr/local/lib_
* _/usr/lib_

if we _ls_ one of those folders we can see a lot of files
```sh
> ls /usr/lib
ld-linux-x86-64.so.2                    libbd_utils.so                            libicui18n.so.71.1                      libsoxr.so
ld-linux.so.2                           libbd_utils.so.2                          libicuio.so                             libsoxr.so.0
ldscripts                               libbd_utils.so.2.1.0                      libicuio.so.71                          libsoxr.so.0.1.2
libBrokenLocale.a                       libbd_vdo.so                              libicuio.so.71.1                        libspeex.so
libBrokenLocale.so                      libbd_vdo.so.2                            libicutest.so                           libspeex.so.1
libBrokenLocale.so.1                    libbd_vdo.so.2.0.0                        libicutest.so.71                        libspeex.so.1.5.1
...
```

**please notic** that all the files start with _lib<name>.so_, this name format is requirement for shared libraries, we will comeback to it later

## using shared libraries 
when you compile your C program, you using some shared library commonly: libc or glibc, those shared libraries provide your C standard functionality, like string, stdio, stdarg, stdlib and so on

sometimes you need more then the standard library, you need encryption support for example, you can use the _-l_ compiler flag to tell the dynamic linker to link another shared library for my program

for example take the next program, it takes a string of Hello world, and create sha1 for that string
```c
#include <stdio.h>
#include <openssl/sha.h>


void printf_hash(const unsigned char *hash){
	int i = 0;

	while(i<SHA_DIGEST_LENGTH){
		printf("%02x", hash[i]);
		i++;
	}
}

int main(int argc, char *argv[]){
	SHA_CTX ctx;
	char msg[] = "Hello world";
	unsigned char hash[SHA_DIGEST_LENGTH+1];

	SHA1_Init(&ctx);
	SHA1_Update(&ctx, msg, sizeof(msg) - 1);
	SHA1_Final(hash, &ctx);

	printf_hash(hash);
	putchar('\n');
}
```

notice that we `#include<openssl/sha.h>`, if we now try to compile it, we will get an error

```sh
> gcc main.c 
/usr/bin/ld: /tmp/ccrD59Yr.o: in function `main':
main.c:(.text+0x93): undefined reference to `SHA1_Init'
/usr/bin/ld: main.c:(.text+0xae): undefined reference to `SHA1_Update'
/usr/bin/ld: main.c:(.text+0xc4): undefined reference to `SHA1_Final'
collect2: error: ld returned 1 exit status
```

the openssl is not part of the standard library, so those functions are not defined in _libc_, we need to tell the linker what libraries we need for that program

```sh
> gcc -lssl -lcrypto main.c
```

**notice** that we can use more then one shared library, 
we can see our executable shared libraries with the _ldd_ command
```sh
> ldd a.out 
	linux-vdso.so.1 (0x...)
	libssl.so.1.1 => /usr/lib/libssl.so.1.1 (0x...)
	libcrypto.so.1.1 => /usr/lib/libcrypto.so.1.1 (0x...)
	libc.so.6 => /usr/lib/libc.so.6 (0x...)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x...)
```

now we can run the program
```sh
> ./a.out 
7b502c3a1f48c8609ae212cdfb639dee39673f5e

> echo -n "Hello world" | sha1sum
7b502c3a1f48c8609ae212cdfb639dee39673f5e  -
```


## write your own shared library
writing shared library is a very simple process, the heavy lifting is done by the dynamic linker,
our development structure will look like so
```
|-- customlib
|   |-- mylib.c
|   `-- mylib.h
`-- src
    `-- main.c
```

our _mylib.c_ contain some simple functionality, first lets see the content of _mylib.h_
```c
// mylib.h

#ifndef _MYLIB_H_
#define _MYLIB_H_

#ifndef NAME_BUFFER_SIZE
	#define NAME_BUFFER_SIZE 64
#endif

int set_name(const char *);
void say(const char *);

#endif
```

now lets inspect our _mylib.c_ source code
```c
#include <stdio.h>
#include <string.h>
#include "mylib.h"


static char name[NAME_BUFFER_SIZE] = "unknown";


int set_name(const char *nname){
	if(strlen(nname) >= sizeof(name)){
		return -1;
	}
	strcpy(name, nname);
	return 0;
}

void say(const char *msg){
	printf("%s: %s", name, msg);
}
```

as we can see, it is a very simple library, it has static buffer called name, it have 2 functions,
`set_name` and `say`, lets compile our code, **importent note**: when creating shared library, the library name must be in the next
format `lib<name>.so`

```sh
> gcc -shared -fpic mylib.c -o libmylib.so
```

---

#### flags description from gcc man page
> **-shared**: "Produce a shared object which can then be linked with other objects to form an executable ..."

> **-fpic**: "Generate position-independent code (PIC) suitable for use in a shared library ..."

---

the output file that shoult we get is:
```sh
> ls
libmylib.so  mylib.c  mylib.h

> file libmylib.so 
libmylib.so: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, BuildID[sha1]=..., with debug_info, not stripped
.
```

now lets use this shared library in our program
```c
// main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mylib.h>


int main(int argc, char *argv[]){
	if(argc < 2 || strcmp(argv[1], "--help") == 0){
		fprintf(stderr, "usage: %s [name]\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	if(set_name(argv[1]) != 0){
		fprintf(stderr, "given name was too long (%s)\n", argv[1]);
		exit(EXIT_FAILURE);
	}

	say("Hello world\n");
}
```

(please note that we included our library with <>, we can also use "", but because that lib is not local to our program, 
it is more correct to use <>)

to compile our program we need to inform the linker where to search for
our custom lib, the most simple way is to provide _-I_ and _-L_ flags like so

```sh
> gcc -I../customlib -L../customlib -lmylib main.c
```

---
#### flags description from gnu man page
> -L: "Add directory dir to the list of directories to be searched for -l."

> -I: "Any directories specified with -I options before -I- are searched only for headers requested with "#include "file""; they are not searched for "#include <file>".  If additional directories are specified with -I options after the -I-, those directories are searched for all #include directives."
---

we can inspect our executable with [nm](https://linux.die.net/man/1/nm) and [ldd](https://man7.org/linux/man-pages/man1/ldd.1.html) for the dynamic symbols and shared libraries
```sh
> nm -D ./a.out
...
                 U exit@GLIBC_2.2.5
                 U fprintf@GLIBC_2.2.5
                 U say
                 U set_name
...

> ldd ./a.out
	linux-vdso.so.1 (0x...)
	libmylib.so => not found
	libc.so.6 => /usr/lib/libc.so.6 (0x...)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x...)
```

with _nm_ we can see that our functions (`say` and `set_name`) are undefined (_U_), so they should be loaded at load time by the
dynamic linker, but with _ldd_ we can see that the dynamic linker dont know where _libmylib.so_ is located, because it couldn't find it in the paths specified in _/etc/ld.so.conf_, it is not recommended to change the content of that file and add paths, so the correct way inform the linker about our shared library location is with environment variable

### LD_LIBRARY_PATH
this environment variable allow us to specify paths to the dynamic linker without editing to contents of _/etc/ld.so.conf_, 
each path is seperated with _:_ like normat _$PATH_ environment variable, we should define that environment variable like so

```sh
> export LD_LIBRARY_PATH=../customlib:$LD_LIBRARY_PATH
> ./a.out
usage: ./a.out [name]

# alternative, allow the environ variable only for a specific program environment

> LD_LIBRARY_PATH=../customlib:$LD_LIBRARY_PATH ./a.out
usage: ./a.out [name]
```

### run the program
now we can run our program with that environment variable set
```sh
> LD_LIBRARY_PATH=../customlib:$LD_LIBRARY_PATH ./a.out foo
foo: Hello world
```
