require!{\fs-tools, optimist}

argv = optimist .default {
    host: \localhost
    port: \27017
    collection: \laweasyread
} .argv
if argv._.length == 0 => argv._ = ["#__dirname/data"]

for path in argv._
    fsTools.walkSync path, /\.json$/, (path, stat, callback) ->
        console.log "Processing #path"
