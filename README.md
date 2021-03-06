# buffer-packer

:warning: This module uses Node´s Buffer! Maybe is not a good ideia to use it in browser environment.

`buffer-packer` can pack and unpack a buffer in a very flexible way.

## get started

```coffee

Packer = require 'buffer-packer'

packer = new Packer 'id:u8b, func:u8b, addr:u16b'

frame = packer.pack {id: 1, func: 2, addr: 0x1234}

console.log frame
# outputs: <Buffer 01 02 12 34> 

console.log packer.unpack frame
# outputs: {size: 4, obj: {id: 1, func: 2, addr: 0x1234}}

```

## install and usage

```bash
npm i buffer-packer

#or

yarn add buffer-packer
```

then, in yout code:

```js
const Packer = require('buffer-packer');

let packer = new Packer( 'id: u16b', {} );

let frame = packer.pack( {id: 12} );
```

## packing

When you instantiate the Packer object you must supply a formater string which is a sequence of tags separated by `,`. Each tag is constructed as an almost mandatory `variable` name, a `:` separator and an always mandatory `format` specifier.

Apart the formater string, you should pass to the class constructor an object with functions in case you are using any `tap` tag in your formater.

### integers

You can use use a tag like `variable:u16l[2]` to include 4 bytes, being 2 unsigned 16 bits values in little endian order from `variable[0]` and `variable[1]`. Also you can use `:s16b=34` to include the value `34` as a big endian signed 16 bits.

Tags starts with a variable name, a `:` as separator and follows format that must start with `s` or `u` to denote signed and unsigned values, then one of `8`, `16` or `32` to set its size, and `l` or `b` to set as little or big endian order. Optionally you can define it as an array with fixed or dynamic size with `[2]` and `[myLength]` respectively, **or** you can set a default value with `=123`

When you set a default value the variable name (before `:`), is optional. Also, if you have a default value, its value will be mandatory during parsing (unpaking).

```coffee
packer = new Packer 'a:u8b, b:u32b, b:u32l, c:u8b[2], c:u8b[len], z:s8b=2, :s8b=2, :s8b=-2'
console.log packer.pack {a:5, b: 0x12345678, c:[1,2,3,4], len:3}
# outputs: <Buffer 05 12 34 56 78 78 56 34 12 01 02 01 02 03 02 02 fe>
```

### float

Float point number format should start with a `f`, can have `32` or `64` as size, and `l` or `b` to set its endianess order.

```coffee
packer = new Packer 'a:f32b, b:f64l'
console.log packer.pack {a:1.2, b:-0.88}
# outputs: <Buffer 3f 99 99 9a 29 5c 8f c2 f5 28 ec bf>
```

### data

This tag can be used for 8 bits data arrays like: js arrays, Buffer or strings.

Format is `data` and a fixed or dynamic data size as in `[2]` or `[leng]`.

```coffee
packer = new Packer 'a:data[3], b:data[3], a:data[len]'
console.log packer.pack {a:'abcdef', b: [1,2], len: 2}
# outputs: <Buffer 61 62 63 01 02 00 61 62>
```

### padding

The tag `:pad[3]` will append 3 bytes of padding zeroes in your pack. When a variable name is supplied it should be a 8 bits values to be used as padding. You also can set a default value to be used as padding with `:pad[3]=255` which will append byte `0xff` 3 times to your pack. As in previous cases the size can be fixed or dynamic.

```coffee
packer = new Packer 'a:u8b, :pad[3], p:pad[2], :pad[padlen]=5, b:u8b'
console.log packer.pack {a: 1, b: 2, p:255, padlen: 4}
# outputs: <Buffer 01 00 00 00 ff ff 05 05 05 05 02>
```

### tap

When you use the tag `variable:tap[func]` this will invoke a function called `func` with current buffer and data as parameter, and will append returned value as property `variable` in your **data object**. After that you can use this value to insert in your pack.

Again, to make it clear, the tag `tap` **will not** make changes in your pack. Here the variable name is used to inform the name of the new property that will be created in your current data object. If you want the value inserted in your pack you must do it explicitly.

```coffee
calcCRC = (buffer, data) ->
    console.log buffer, data
    # outputs: <Buffer 01 02> {id: 1, func: 2}
    acc = 0
    acc += v for v in buffer
    return acc

packer = new Packer 'id:u8b, func:u8b, crc:tap[calcCRC], crc:u16b', {calcCRC}
console.log packer.pack {id: 1, func: 2}
# outputs: <Buffer 01 02 00 03>
```

## examples

```coffee
Packer = require 'buffer-packer'

data = {a:1, b:0x1234, c:[1,2,3,4,5], len:3}

packer = new Packer 'b:u16l, c:u16b[2]'
console.log packer.pack data
# outputs: <Buffer 34 12 00 01 00 02>

packer = new Packer 'len:u8b, c:u16l[len]'
console.log packer.pack data
# outputs: <Buffer 03 01 00 02 00 03 00>

packer = new Packer 'c:u16b[2], crc:tap[calcCRC], crc:u32b', {calcCRC: (buf) => return 0x12345678}
console.log packer.pack data
# outputs: <Buffer 00 01 00 02 12 34 56 78>
```

# unpacking

Once you have a packer instance you can feed it with a Buffer to get the original data object used to pack it. Example:

```coffee
packer = new Packer 'a:u8b, b:u32l, :pad[3] , text:data[2], c:u8b[len], z:u8b=12, :u8b=14'

frame = packer.pack {a:5, b: 0x12345678, c:[1,2,3,4], text:'string', len:3}

console.log frame
# outputs: <Buffer 05 12 34 56 78 78 56 34 12 00 00 00 01 02 01 02 03 0c 0e> 

console.log packer.unpack frame.slice(0,5), {len: 3}
# outputs: {err: 'too short'}

console.log packer.unpack frame
# will throw "Missing dynamic size `len`"

console.log packer.unpack frame, {len: 3}
# outputs: {size: 19, obj: { len: 3, a: 5, b: 305419896, text: <Buffer 73 74>, c: [ 1, 2, 3 ], z: 12 }}

```

**Important** points to note:

- note we had to provide a starting data object to unpack with `len` initialized so it knows the dynamic size of c property
- data field always return as Buffer (see the `text` field above)
- the parsed `c` and `text` are both smaller then original values since we only packed part of them
- the last field does not appears on the result since its a unnamed constant value
- the returned object has the property `obj` when the unpacking succeed *or* `err` when it fails (in this case `err` is a string with a brief description of the cause of failure)
- when unpacking succeed you also got a `size` property, note that if you have any dynamic sized property in your pack then your size will change between packs
- recoverable errors like being `too short` or `wrong default` do not throw, so you can wait for more data an try again, for example. In other hand an error like `Missing dynamic size` will throw since is likely to be a design error.

> parsing works one tag per turn, and parsed values are appended to result as soon they are available. In previous example we had to supply the value of `len` from beginning, *but*, if we had a tag resolving the value of `len` before it was needed (to define `c`´s size in that example), then we could execute `unpack` without any starting object.

# unpacking with streams
