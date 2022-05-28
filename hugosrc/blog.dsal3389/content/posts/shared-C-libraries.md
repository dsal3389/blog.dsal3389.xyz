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

when we compile C code, we using shared libraries all the time without knowing it, to see what shared libraries some executable is using we can use the `ldd` command like so

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
the _dynamic linker_ read the contents of `/etc/ld.so.conf`, this file contain the path that tells the _dynamic linker_, where to search for the required shared library, most of the time it will be stored in

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

**please notic** that all the files start with `lib<name>.so`, this name format is requirement for shared libraries, we will comeback to it later

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

notice that we _#include<openssl/sha.h>_, if we now try to compile it, we will get an error

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
`set_name` and `say`|
