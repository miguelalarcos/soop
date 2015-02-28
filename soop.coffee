visitSchemaArray = (array, schema, func, out)->
  ret = []
  if not _.has(schema, 'type')
    schema_ = schema
    schema = {}
    schema.type = schema_[0]
  for value in array
    if _.isArray(value)
      ret.push visitSchemaArray(value, schema.type, func, out)
    else if _.isObject(value) and not _.isFunction(value) and not schema.type.prototype instanceof Base
      ret.push visitSchemaObject(value, schema.type, func, out)
    else
      ret.push func(value, schema, out)
  ret

visitSchemaObject = (obj, schema, func, out) ->
  if schema is undefined then schema = {}
  ret = {}
  for key, value of obj
    if key == '_id' or _.isFunction(obj[key])
      continue
    if _.isArray(value)
      ret[key] = visitSchemaArray(value, schema[key], func, out)
    else if _.isObject(value) and not _.isFunction(value)
      ret[key] = visitSchemaObject(value, schema[key].type.schema, func, out)
    else
      ret[key] = func(value, schema[key], out)
  for key of schema
    if key not in _.keys(obj)
      ret[key] = undefined
  return ret

class Base
  constructor: (args, doFindOne)->
    if doFindOne is undefined
      doFindOne = true

    if args._id
      @_id = args._id
      if doFindOne
        args = @constructor.collection.findOne(args._id)
    else
      @_id = null

    schema = @constructor.schema
    values = visitSchemaObject args, schema, (x, node)->
      klass = node.type[0] or node.type
      if klass and klass.prototype instanceof Base
        new klass({_id: x})
      else
        x

    for key, value of values
      @[key] = value

  @find : (selector) ->
    klass = @
    if selector is undefined or selector is null
      selector = {}
    (new klass(doc, false) for doc in @collection.find(selector).fetch())

  save: ->
    doc = {}
    schema = @constructor.schema

    #s = visitSchemaObject schema,{}, (x)-> x #clone the schema
    #ss = new SimpleSchema s
    #ctx = ss.newContext()

    recip = []
    valid = visitSchemaObject @, schema, ( (x, node, out)->
      if x is undefined and node.optional == true
        return true
      klass = node.type[0] or node.type
      if klass is String
        if _.isString(x) then out.push true else out.push false
      else if klass is Number
        if _.isNumber(x) then out.push true else out.push false
      else if klass is Boolean
        if _.isBoolean(x) then out.push true else out.push false
      else if klass is Date
        if _.isDate(x) then out.push true else out.push false
      else if x instanceof klass
        out.push true
    ), recip

    console.log valid, recip
    #if not _.all(_.flatten valid)
    #  throw 'not all are valid'

    doc = visitSchemaObject @, schema, (x, node) ->
      klass = node.type[0] or node.type
      if klass
        if klass.prototype instanceof Base
          x.save()
          x._id
        else
          x

    if @_id is null
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(@_id, {$set: doc})

properties = (self, props) -> Object.defineProperties self.prototype, props

class inLine
  constructor: (args)->
    for key, value of args
      @[key] = value

soop = {}
soop.Base  = Base
soop.properties = properties
soop.inLine = inLine

