{expect} = require 'chai'
Packer = require '../lib/buffer-packer.js'

describe 'packer', ->

    it 'pack integers', ->
        packer = new Packer 'a:u8b, b:u32l, b:u32b'
        r = packer.pack {a:1, b:0x123456}
        expect(r).to.be.deep.equal Buffer.from [0x01, 0x56, 0x34, 0x12, 0x00, 0x00, 0x12, 0x34, 0x56]

    it 'pack array of integers', ->
        packer = new Packer 'a:u16b[2], len:u8b, a:u16l[len]'
        r = packer.pack {a:[0x1122, 0x5566, 0x8899], len:3}
        expect(r).to.be.deep.equal Buffer.from [0x11, 0x22, 0x55, 0x66, 0x03, 0x22, 0x11, 0x66, 0x55, 0x99, 0x88]

    it 'pack integers with defaults', ->
        packer = new Packer 'a:u8b=5, :s8b=-5, z:u8b=5'
        r = packer.pack {a:3}
        expect(r).to.be.deep.equal Buffer.from [0x03, 0xfb, 0x05]

    it 'pack floats', ->
        packer = new Packer 'a:f32b, b:f64l'
        r = packer.pack {a:1.8, b:-45.99}
        expect(r).to.be.deep.equal Buffer.from [0x3f, 0xe6, 0x66, 0x66, 0x1f, 0x85, 0xeb, 0x51, 0xb8, 0xfe, 0x46, 0xc0]

    it 'pack paddings', ->
        packer = new Packer 'a:u8b, :pad[1], :pad[len]=254, p:pad[2], a:u8b'
        r = packer.pack {a:1, len:2, p:2}
        expect(r).to.be.deep.equal Buffer.from [0x01, 0x00, 0xfe, 0xfe, 0x02, 0x02, 0x01]

    it 'pack strings/arrays/buffers', ->
        packer = new Packer 'a:data[4], b:data[n], c:data[4]'
        r = packer.pack {a:[1,2,3], b:'string', c:Buffer.from([10,11,12,13,14]), n:3}
        expect(r).to.be.deep.equal Buffer.from [0x01, 0x02, 0x03, 0x00, 0x73, 0x74, 0x72, 0x0a, 0x0b, 0x0c, 0x0d]

    it 'resolves tap functions', ->
        packer = new Packer 'a:u16l, insert:tap[func1], insert:u16b', {func1: (buf) -> buf.length}
        r = packer.pack {a: 4}
        expect(r).to.be.deep.equal Buffer.from [0x04, 0x00, 0x00, 0x02]


describe 'unpacker', ->
