#! /usr/bin/env coffee

fs = require 'fs'

start = 10
keepLast = no
step = 10
nDigits = 3

regex = new RegExp "^\\d{#{nDigits}}\\."

fs.readdir '.', 'utf8', (err, files) ->
    filtered = files.filter (f) -> regex.test f
    filtered.sort()
    target = start
    plan = filtered.map (f, idx) ->
        target = f.slice(0, nDigits) if idx == filtered.length-1 and keepLast
        p = {curr: f.slice(0, nDigits),name: f.slice(nDigits), target: ('000000'+target).slice(-nDigits)}
        target += step
        p
    # console.log plan
    # FIXME isso conta que o nome do arquivo seja diferente entre os arquivos!!!
    # senao havera erro de duplicacao durante o processo
    # neste ponto o array pode ser organizado para evitar este problema
    n = 0
    plan.forEach (f) ->
        if f.curr != f.target
            fs.renameSync f.curr+f.name, f.target+f.name
            n++

    console.log "\nRenomeados #{n} arquivos!\n"
