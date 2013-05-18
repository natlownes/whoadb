fs   = require 'fs'
uuid = require 'node-uuid'


# *WhoaDB* stores and reads JSON-able objects to and from a flat file.
#
#


class WhoaDB
  constructor: (filepath) ->
    @dbpath = filepath
    @_initializeStore(filepath)

  all: (collectionName) ->
    if @store[collectionName]
      record for _, record of @store[collectionName]
    else
      []

  find: (collectionName, objectId) -> @store[collectionName]?[objectId]

  save: (record) ->
    if not @store[record._collection]?
      @store[record._collection] = {}

    if not record.id? then record.id = uuid.v4()

    @store[record._collection][record.id] = record
    @persist()

    record

  destroy: (record) ->
    delete @store[record._collection]?[record.id]
    @persist()

    record

  persist: ->
    fs.writeFileSync(@dbpath, JSON.stringify(@store), 'UTF-8')

  drop: ->
    @store = {}
    @persist()

  load: -> @_initializeStore(@dbpath)

  _initializeStore: (filepath) ->
    @store = if filepath? and fs.existsSync(filepath)
      JSON.parse(fs.readFileSync(filepath, 'UTF-8'))
    else
      {}


module.exports = WhoaDB
