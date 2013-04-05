require!<[async fs fs-tools file mongodb optimist]>

const MONGO_OPTS =
    w: 1

create_task = (db, collection_name, files) ->
    !(callback) ->
        console.log "Open collection #collection_name"
        err, collection <-! db.collection collection_name
        if err => return callback err

        err, subtask <-! async.map files, (file, callback) ->
            callback null, !(callback) ->
                console.log "Write #file"
                data = fs.readFileSync file, \utf8 |> JSON.parse
                err <-! collection.insert data
                callback err
        if err => return callback err

        err <-! async.parallel subtask
        callback err

create_db_close_callback = (db, callback) ->
    !(err) ->
        db.close!
        callback err

main = !->
    callback = !(err) ->
        if err
            console.error err

    argv = optimist .default {
        mongo_uri: process.env.MONGOLAB_URI or \mongodb://localhost:27017/laweasyread
        data: "#__dirname/data"
    } .argv

    console.log 'Open DB'
    err, db <-! mongodb.Db.connect argv.mongo_uri, MONGO_OPTS
    if err => return callback err
    callback := create_db_close_callback db, callback

    console.log 'Drop database'
    err <-! db.dropDatabase
    if err => return callback err

    filelist =
        article: []
        statute: []

    console.log 'Find JSON to import'
    fsTools.walkSync "#{argv.data}/law", !(path) ->
        match path
        | /article\.json$/ => filelist.article.push path
        | /statute\.json$/ => filelist.statute.push path

    err, task <-! async.map (Object.keys filelist), (key, callback) ->
        callback null, (create_task db, key, filelist[key])

    console.log 'Start to insert data'
    err <-! async.parallel task
    if err => return callback err

    console.log 'Done'
    callback null

main!
