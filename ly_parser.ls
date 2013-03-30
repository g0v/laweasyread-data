require!{fs, mkdirp, optimist}

parseHTML = (path) ->
    ret =
        statute:
            name: []
        article: []

    for file in fs.readdirSync path
        console.log "Processing #path/#file"

    ret

writeJSON = (path, json) ->
    console.log "Write to #path"
    fs.writeFileSync path, JSON.stringify json, '', 4

main = ->
    out = optimist.argv.out || "output"
    for path in optimist.argv._
        m = path.match /([^/]+\/[^/]+)\/?$/
        outdir = "#out/#{m.1}"

        mkdirp.sync outdir

        res = parseHTML path

        for key, value of res
            writeJSON "#outdir/#key.json", res[key]
main!
