# WhoaDB(!)

Not actually a DB:   But write JSON objects to a flat file using this if you
want.

This is a component I extracted from a test REST server used if you're working
on a front end app that RESTfully stores data and you want to click around for a
little bit without firing up an actual backend.


```coffeescript
WhoaDB = require 'whoadb'

persistFile = '/tmp/whoadb.json'

db = new WhoaDB(persistFile)

record = { name:  "food", _collection: "edibles" }

db.insert(record)

# record object is assigned an id

record.name = "non-food"

db.insert(record)

# record updated

db.destroy(record)
```


