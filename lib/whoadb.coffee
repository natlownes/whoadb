md5         = require 'MD5'
fs          = require 'fs'


# *WhoaDB* stores and reads JSON-able objects to and from a flat file.
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

  save: (record) ->
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
      JSON.parse(fs.readFileSync(filepath, 'UTF-8'))
    else
      {}


module.exports = WhoaDB
