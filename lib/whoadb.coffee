md5         = require 'MD5'
fs          = require 'fs'
# *WhoaDB* stores JSON-able objects to a flat file.
#
#

class WhoaDB
  constructor: (filepath) ->
    @dbpath = filepath
    @store  = @initializeStore(filepath)

  all: (collectionName) ->
    if @store[collectionName]
      record for _, record of @store[collectionName]
    else
      []

  find: (collectionName, objectId) -> @store[collectionName]?[objectId]

  insert: (record) ->
    if not @store[record._collection]?
      @store[record._collection] = {}

    if not record.id
      record.id = md5(JSON.stringify(record))

    @store[record._collection][record.id] = record
    @persist()

    record

  destroy: (record) ->
    delete @store[record._collection]?[record.id]
    @persist()

    record

  persist: ->
    fs.writeFileSync(@dbpath, JSON.stringify(@store), 'UTF-8')

  initializeStore: (filepath) ->
    if filepath? and fs.existsSync(filepath)
      try
        JSON.parse(fs.readFileSync(filepath, 'UTF-8'))
      catch error
        console.log "\n
        #{error} - JSON parsing error trying to parse #{filepath}, continuing...
        \n"
        {}
    else
      {}


module.exports = WhoaDB
