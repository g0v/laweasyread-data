require!{async, fs, \fs-tools, file, mongodb, optimist}
mongoUri = process.env.MONGOLAB_URI or 'mongodb://localhost:27017/laweasyread'

create_task = (db, collection_name, files) ->
    (cb) ->
        (err, collection) <- db.collection collection_name
        console.log "Open collection #collection_name"
        for file in files
            console.log "Write #file"
            fs.readFileSync file, \utf8 |> JSON.parse |> collection.insert
        cb null

main = ->
    argv = optimist .default {
        uri: mongoUri
    } .argv

    err, db <- mongodb.Db.connect argv.uri
    if err => console.log err; return
    console.log "Open DB"

    data =
        article: []
        statute: []

    fsTools.walkSync "#__dirname/data", /article\.json$/, (path) ->
        data.article.push path

    fsTools.walkSync "#__dirname/data", /statute\.json$/, (path) ->
        data.statute.push path

    (err, res) <- async.map (Object.keys data), (key, cb) ->
        cb null, (create_task db, key, data[key])

    (err, res) <- async.series res

    db.close!

    console.log "Done"

main!
