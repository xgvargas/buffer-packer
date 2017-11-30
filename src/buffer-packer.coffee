module.exports = class Packer

    ###
    ###
    constructor: (struct, @ops={}) ->

        @len = 0

        @struct = struct.replace(/[^a-zA-Z0-9:=,\[\]-]/g, '').split(',').map (descr) =>
            [name, format] = descr.split ':'

            return unless format

            if m = format.match ///^(s|u) (8|16|32) (l|b) (?: (?:\[ (?:(\d+)|(\w+)) \]) | (?: = (-?\d+)) )? $///
                esize = +m[2]/8
                len = +(m[4] || 1)
                dynamic = m[5]
                len = 0 if dynamic
                sign = m[1]=='s'
                array = !!(m[4] or m[5])
                field = {size: len*esize, len, def: +m[6], dynamic, esize, endian: m[3], type: 'int', sign, array}

            else if m = format.match /^f(32|64)(l|b)$/
                field = {size: +m[1]/8, endian: m[2], type: 'float'}

            else if m = format.match /^pad\[(?:(\d+)|(\w+))\](?:=(-?\d+))?$/
                field = {size: +(m[1] || 0), type: 'padding', dynamic: m[2], def: +m[3]}

            else if m = format.match /^data\[(?:(\d+)|(\w+))\]$/
                field = {size: +(m[1] || 0), type: 'data', dynamic: m[2]}

            else if m = format.match /^tap\[(\w+)\]$/
                field = {size: 0, type: 'tap', fn: m[1]}

            throw new Error "Unknown format: `#{format}`" unless field?

            field = Object.assign field, {name, offset: @len}
            @len += field.size

            field

    ###
    ###
    pack: (data) ->

        buf = Buffer.alloc @len

        fix = 0

        for f in @struct

            continue unless f

            # throw new Error "Missing value: `#{f.name}`" if f.type not in ['padding', 'tap'] and not data[f.name]?

            switch f.type
                when 'int'
                    p = f.offset+fix

                    if f.dynamic
                        throw new Error "Missing dynamic size `#{f.dynamic}`" unless data[f.dynamic]
                        f.len = data[f.dynamic]
                        f.size = f.len*f.esize
                        tmp = Buffer.alloc buf.length+f.size
                        buf.copy tmp
                        buf = tmp
                        fix += f.size

                    if f.array
                        d = data[f.name]
                        throw new Error "Value `#{f.name}` must be array" unless Array.isArray d
                    else
                        if f.def
                            d = [data[f.name] || f.def]
                        else
                            throw new Error "Missing value: `#{f.name}`" unless data[f.name]?
                            d = [data[f.name]]

                    u = if f.sign then 'Int' else 'UInt'
                    e = if f.esize == 1 then '' else if f.endian=='b' then 'BE' else 'LE'

                    fn = "write#{u}#{8*f.esize}#{e}"

                    for n in [0...f.len] by 1
                        buf[fn] d[n], p
                        p += f.esize

                when 'float'
                    throw new Error "Missing value: `#{f.name}`" unless data[f.name]?
                    s = if f.size==4 then 'Float' else 'Double'
                    e = if f.endian=='b' then 'BE' else 'LE'

                    buf["write#{s}#{e}"] data[f.name], f.offset+fix

                when 'data'
                    throw new Error "Missing value: `#{f.name}`" unless data[f.name]?
                    d = Buffer.from data[f.name]
                    if f.dynamic
                        throw new Error "Missing dynamic size `#{f.dynamic}`" unless data[f.dynamic]
                        tmp = Buffer.alloc buf.length+data[f.dynamic]
                        buf.copy tmp
                        buf = tmp
                        d.copy buf, f.offset+fix, 0, +data[f.dynamic]
                        fix += data[f.dynamic]
                    else
                        d.copy buf, f.offset+fix, 0, f.size

                when 'padding'
                    p = f.offset+fix
                    if f.dynamic
                        throw new Error "Missing dynamic size `#{f.dynamic}`" unless data[f.dynamic]
                        tmp = Buffer.alloc buf.length+data[f.dynamic]
                        buf.copy tmp
                        buf = tmp
                        fix += data[f.dynamic]

                    buf.fill data[f.name] || f.def || 0, p, p+(f.size || data[f.dynamic])

                when 'tap'
                    throw new Error "Undefined tap function: `#{f.fn}`" unless @ops[f.fn]

                    data[f.name] = @ops[f.fn](buf.slice(0, f.offset+fix), data)

        return buf

    ###
    ###
    unpack: (buf, obj={}, ops={forceDef:true}) ->

        fix = 0

        for f in @struct

            continue unless f #and f.name

            switch f.type
                when 'int'
                    p = f.offset+fix
                    if f.dynamic
                        throw new Error "Missing dynamic size `#{f.dynamic}`" unless obj[f.dynamic]
                        f.len = obj[f.dynamic]
                        f.size = f.len*f.esize
                        fix += f.size

                    return null unless buf.length >= p + f.size

                    u = if f.sign then 'Int' else 'UInt'
                    e = if f.esize == 1 then '' else if f.endian=='b' then 'BE' else 'LE'

                    fn = "read#{u}#{8*f.esize}#{e}"

                    d = []
                    for n in [0...f.len] by 1
                        d.push buf[fn] p
                        p += f.esize

                        if f.array
                            obj[f.name] = d
                        else
                            if f.def and not f.name
                                return null unless d[0] == f.def
                            obj[f.name] = d[0] if f.name

                when 'float'

                    return null unless buf.length >= f.offset+fix + f.size

                    s = if f.size==4 then 'Float' else 'Double'
                    e = if f.endian=='b' then 'BE' else 'LE'

                    obj[f.name] = buf["read#{s}#{e}"] f.offset+fix

                when 'data'
                    p = f.offset+fix
                    if f.dynamic
                        throw new Error "Missing dynamic size `#{f.dynamic}`" unless obj[f.dynamic]
                        f.size = obj[f.dynamic]
                        fix += f.size

                    return null unless buf.length >= p + f.size

                    obj[f.name] = Buffer.alloc f.size
                    buf.copy obj[f.name], 0, p, p+f.size

        return obj



    ###
    ###
    createUnpacker: ->
