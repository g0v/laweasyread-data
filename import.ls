require!{async, fs, \fs-tools, file, mongodb, optimist}

mongoUri = process.env.MONGOLAB_URI or 'mongodb://localhost:27017/laweasyread'
const MONGO_OPTS =
    w: 1

create_task = (db, collection_name, files) ->
    (cb) ->
        (err, collection) <- db.collection collection_name
        console.log "Open collection #collection_name"
        if err
            cb err
            return

        (err, res) <- async.map files, (file, cb) ->
            cb null, (cb) ->
                console.log "Write #file"
                data = fs.readFileSync file, \utf8 |> JSON.parse
                (err, res) <- collection.insert data
                cb err

        if err
            cb err
            return

        (err, res) <- async.series res
        cb err

main = ->
    argv = optimist .default {
        uri: mongoUri
    } .argv

    err, db <- mongodb.Db.connect argv.uri, MONGO_OPTS
    if err => console.log err; return
    console.log "Open DB"

    data =
        article: []
        statute: []

    fsTools.walkSync "#__dirname/data", (path) ->
        match path
        | /article\.json$/ => data.article.push path
        | /statute\.json$/ => data.statute.push path

    (err, res) <- async.map (Object.keys data), (key, cb) ->
        cb null, (create_task db, key, data[key])

    (err, res) <- async.series res
    if err => console.error err else console.log "Done"

    db.close!

main!
