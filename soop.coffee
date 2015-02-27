class Base
  constructor: (args)->
    if args._id
      args = @collection.findOne(args._id)# or args
    else
      @_id = null

    schema = @_schema
    for field in _.keys(args)
      if field == '_id'
        continue
      if _.isArray(schema[field].type)
        if schema[field].type[0].prototype instanceof Base
          ret = []
          for _id in args[field]
            ret.push(new schema[field].type[0]({_id: _id}))
          @[field] = ret
      else if schema[field].type.prototype instanceof Base
        @[field] = new schema[field].type[0]({_id: _id})
      else
        @[field] = args[field]

  @find : (selector) ->
    klass = @
    if selector is undefined or selector is null
      selector = {}
    (new klass(doc) for doc in @collection.find(selector).fetch())

  save: ->
    doc = {}
    schema = @_schema
    for field in _.keys(schema)
      if field == '_id'
        continue

      if _.isArray(schema[field].type)
        if schema[field].type[0].prototype instanceof Base
          ret = []
          for v in @[field]
            if v._id is null
              v.save()
            ret.push v._id
          doc[field] = ret
      else if schema[field].type.prototype instanceof Base
        if @[field]._id is null
          @[field].save()
        doc[field] = @[field]._id
      else
        doc[field] = @[field]

    if @_id is null
      @_id = @collection.insert(doc)
    else
      @collection.update(@_id, {$set: doc})

properties = (self, props) -> Object.defineProperties self.prototype, props

soop = {}
soop.Base  = Base
soop.properties = properties

