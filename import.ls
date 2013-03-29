require!{async, fs, \fs-tools, file, mongodb, optimist}
mongoUri = process.env.MONGOLAB_URI or 'mongodb://localhost:27017/laweasyread'
const MAP =
    * directory: "#__dirname/data/statute"
      collection: \statute
    * directory: "#__dirname/data/article"
      collection: \article

main = ->
    argv = optimist .default {
        uri: mongoUri
    } .argv

    err, db <- mongodb.Db.connect argv.uri
    if err => console.log err; return
    console.log "Open DB"

    (err, res) <- async.map MAP, (map, cb) ->
        data =
            collection: map.collection
            path: []
        fsTools.walkSync map.directory, /\.json$/, (path) ->
            data.path.push path
        cb null, data
    if err => console.log err

    (err, res) <- async.map res, (map, cb) ->
        (err, collection) <- db.collection map.collection
        if err => console.log err; cb err; return
        console.log "Open collection `#{map.collection}'"
        (err, res) <- async.map map.path, (path, cb) ->
            fs.readFileSync path, \utf8 |> JSON.parse |> collection.insert
            console.log "Import #path"
            cb null
        cb null
    if err => console.log err

    db.close!
main!
