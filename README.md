# WhoaDB(!)

Not actually a DB:   But read/write JSON objects to/from a flat file using this if you
want.

[![Build
Status](https://travis-ci.org/natlownes/whoadb.png?branch=master)](https://travis-ci.org/natlownes/whoadb)

This is a component I extracted from a test REST server used if you're working
on a front end app that RESTfully stores data and you want to click around for a
little bit without firing up an actual backend.

### Starting

```
npm install whoadb`
```

```coffeescript
WhoaDB = require 'whoadb'

persistFile = '/tmp/whoadb.json'

db = new WhoaDB(persistFile)

```

### Finding

```coffeescript
record1 = { id: 'fff', name:  "food", _collection: "edibles" }
record2 = { id: 'ggg', name:  "more food", _collection: "edibles" }

db.save(record1)
db.save(record2)

db.all('edibles')

# => [ record1, record2 ]

db.find('edibles', 'fff')

# => record1

```

### Create & Update & Destroy

```coffeescript
record = { name:  "food", _collection: "edibles" }

db.save(record)

# record object is assigned an id

record.name = "non-food"

db.save(record)

# record updated

db.destroy(record)

```

### Records without the ```_collection``` key

If a record doesn't have a ```_collection``` key, it'll be added to the
```undefined``` collection.

```coffeescript
record1 = { id: 'fff', name:  "food" }

db.save(record1)

db.all(undefined)

# => [ record1 ]

db.find(undefined, 'fff')

# => record1

```

I'll be throwing the aforementioned test REST server up here as well so the
existence of this in isolation doesn't seem quite so damned weird.
