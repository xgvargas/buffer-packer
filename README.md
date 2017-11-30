# buffer-packer

:warning: This module uses Node´s Buffer! Maybe´s not a good ideia to use it in browser environment.

`buffer-packer` can pack and unpack a buffer in a very flexible way.

## get started

```coffee

Packer = require 'buffer-packer'

packer = new Packer 'id:u8b, func:u8b, addr:u16b'

frame = packer.pack {id: 1, func: 2, addr: 0x1234}

console.log frame
# outputs: <Buffer 01 02 12 34> 

console.log packer.unpack frame
# outputs: {id: 1, func: 2, addr: 0x1234}

```

## install

```bash
npm i buffer-packer

#or

yarn add buffer-packer
```

## usage


## examples

```coffee

Packer = require 'buffer-packer'

data = {a:1, b:0x1234, c:[1,2,3,4,5], l:2}

packer = new Packer 'b:u16l, c:u16b[2]'
console.log packer.pack data
# outputs: <Buffer 01 00 00 01 00 02>

```

## dev
