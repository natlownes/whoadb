expect = require('chai').expect
fs     = require 'fs'
path   = require 'path'
md5    = require 'MD5'

WhoaDB = require('../index')


describe 'WhoaDB', ->
  beforeEach ->
    @dbpath = path.resolve 'tmp/testdb.json'
    fs.unlinkSync(@dbpath) if fs.existsSync(@dbpath)

  context 'when db file does exist', ->
    context 'and contains parsable json', ->
      beforeEach ->
        data = JSON.stringify(
          a: 'horses'
          b: 'thieves'
        )
        fs.writeFileSync(@dbpath, data)

      it 'should load that json into the @store', ->
        db = new WhoaDB(@dbpath)

        expect( db.store['a'] ).to.equal    'horses'
        expect( db.store['b'] ).to.equal    'thieves'

    context 'and contains no parsable json', ->
      beforeEach ->
        data = 'RAAAAAAWR!!!!'
        fs.writeFileSync(@dbpath, data)

      it 'should throw error', ->
        operation = =>
          new WhoaDB(@dbpath)

        expect( operation ).to.throw SyntaxError

  context 'when db file does not exist', ->
    it 'should set an empty @store object', ->
      db = new WhoaDB(@dbpath)
      expect( db.store ).to.be.empty
      expect( db.store ).to.be.an 'object'

  describe '#persist', ->
    it 'should create a new file', ->
      db = new WhoaDB(@dbpath)
      db.persist()

      expect( fs.existsSync(@dbpath) ).to.be.true

    it 'should write db to that file', ->
      db = new WhoaDB(@dbpath)
      db.store =
        a: 'horses'
        b: 'heist'

      db.persist()

      data = fs.readFileSync(@dbpath).toString('utf-8')

      expect( data ).to.equal '{"a":"horses","b":"heist"}'

  describe '#load', ->
    beforeEach ->
      store =
        villains:
          4:
            name: 'DOOM'

      fs.writeFileSync(@dbpath, JSON.stringify(store), 'UTF-8')

    it 'should load the store from @dbpath', ->
      db = new WhoaDB(@dbpath)
      db.load()

      expect( db.find('villains', 4 ).name ).to.equal 'DOOM'

    context 'when @store has existing, unpersisted data', ->
      beforeEach ->
        @db = new WhoaDB(@dbpath)
        @db.store =
          villians:
            3:
              name: 'Oh no'

      it 'is going to lose that existing data', ->
        expect( @db.find('villians', 3).name ).to.equal 'Oh no'

        @db.load()

        expect( @db.find('villians', 3) ).to.be.undefined

  describe '#drop', ->
    beforeEach ->
      @db = new WhoaDB(@dbpath)

      for i in [0..10]
        obj =
          name: "Object # #{i}"
        @db.save(obj)

    it 'should set @store to empty object', ->
      expect( @db.store ).not.to.be.empt

      @db.drop()

      expect( @db.store ).to.be.empty

    it 'should write empty object to disk', ->
      expect( @db.store ).not.to.be.empt

      @db.drop()

      data = JSON.parse(fs.readFileSync(@dbpath, 'UTF-8'))

      expect( data ).to.be.an 'object'
      expect( data ).to.be.empty

  describe 'methods dealing with records', ->
    beforeEach ->
      @db = new WhoaDB(@dbpath)

    describe '#save', ->
      context 'when saving a record with no _collection key', ->
        beforeEach ->
          @record =
            name: 'Bookies'

        it 'should add it to @store[undefined]', ->
          @db.save(@record)

          expect( @db.store[undefined][@record.id].name ).
            to.equal 'Bookies'

      context 'when saveing a record without an id', ->
        beforeEach ->
          @record =
            name: 'Heath Bell'
            _collection: 'relievers'

        it 'should generate an id for the record', ->
          expectedId = md5(JSON.stringify(@record))

          @db.save(@record)

          expect( @db.store['relievers'][expectedId]['id']).to.
            equal expectedId

        it 'should set the id on the returned record', ->
          expectedId = md5(JSON.stringify(@record))

          record = @db.save(@record)

          expect(record.id).to.equal expectedId

        it 'should save the record to the @store', ->
          @db.save(@record)

          expect( @db.store['relievers'][@record.id]['name'] ).
            to.equal 'Heath Bell'

        it 'should write the record to the file', ->
          @db.save(@record)

          data = fs.readFileSync(@dbpath).toString('utf-8')

          store = JSON.parse(data)

          expect( store['relievers'][@record.id]['name'] ).
            to.equal 'Heath Bell'

      context 'when updating an existing record', ->
        beforeEach ->

          @record =
            name: 'Rollie Fingers'
            _collection: 'relievers'

          @db.save(@record)

        it 'should update the attributes', ->
          @record.name = 'Rollie "Several" Fingers'

          @db.save(@record)

          expect( @db.store['relievers'][@record.id].name ).
            to.equal 'Rollie "Several" Fingers'

        it 'should not create a duplicate', ->
          @record.name = 'Rollie "Several" Fingers'

          @db.save(@record)

          expect( @db.all('relievers') ).to.have.length 1

      context "when the @store has no object for record's _collection", ->
        beforeEach ->
          @record =
            name: 'Heath Bell'
            _collection: 'relievers'
          @db.store['relievers'] = undefined

        it 'should create an object for that _collection name', ->
          @db.save(@record)

          expect( @db.store['relievers'] ).to.be.an 'object'

    describe '#destroy', ->
      context 'when called with a record that does not exist', ->
        beforeEach ->
          @record =
            name: 'Milt Thompson'

        it 'should not throw an error', ->
          operation = =>
            @db.destroy(@record)

          expect( operation ).not.to.throw Error

      context 'when called with a record existing in db', ->
        beforeEach ->
          @record =
            name: 'Matt Williams',
            _collection: '3B'

          @db.save(@record)

        it 'should remove the record from the store', ->
          @db.destroy(@record)

          expect( @db.store['3B'] ).to.be.empty

        it 'should remove the record from the file', ->
          @db.destroy(@record)

          data = fs.readFileSync(@dbpath).toString('utf-8')

          store = JSON.parse(data)

          expect( store['3B'] ).to.be.empty

        context 'with multiple records', ->
          beforeEach ->
            @record =
              name: 'Matt Williams',
              _collection: '3B'

            @record2 =
              name: 'Mike Schmidt'
              _collection: '3B'

            @db.save(@record2)
            @db.save(@record)

          it 'when destroying one, should not destroy all from store', ->
            @db.destroy(@record)

            expect( @db.store['3B'][@record2.id].name ).
              to.equal 'Mike Schmidt'

          it 'when destroying one, should not destroy all from file', ->
            @db.destroy(@record)

            data = fs.readFileSync(@dbpath).toString('utf-8')

            store = JSON.parse(data)

            expect( store['3B'][@record2.id].name ).
              to.equal 'Mike Schmidt'

    describe '#all', ->

      context 'with nothing in that collection', ->
        beforeEach ->
          @db.store['honk'] = undefined

        it 'should return an empty array', ->
          expect( @db.all('honk') ).to.be.an 'array'
          expect( @db.all('honk') ).to.be.empty

      context 'with something in that collection', ->
        beforeEach ->
          @record =
            name: 'Mitch Williams'
            _collection: 'relievers'

          @db.save(@record)

        it 'should return all objects in that collection', ->
          expect( @db.all('relievers') ).to.include @record

    describe '#find', ->

      context 'when collection does not exist', ->
        beforeEach ->
          @db.store['fff'] = undefined

        it 'should return undefined', ->
          expect( @db.find('fff', 'someid') ).
            to.be.undefined

      context 'when collection does exist, record does not', ->
        beforeEach ->
          record =
            name: 'Deadmau5'
            _collection: 'people'

          @db.save( record )

        it 'should return undefined', ->
          expect( @db.find('people', 'ddd') ).to.be.undefined

      context 'when record exists in collection', ->
        beforeEach ->
          @record =
            name: 'RJD2'
            _collection: 'people'

          @db.save( @record )

        it 'should return record', ->
          expect( @db.find('people', @record.id) ).
            to.equal @record

