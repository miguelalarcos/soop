visitSchemaArray = (array, schema, func)->
  ret = []
  for value in array
    if schema
      ret.push func(value, schema)
    else
      ret.push func(value)
  ret

visitSchemaObject = (obj, schema, func) ->
  if schema is undefined then schema = {}
  ret = {}
  for key, value of obj
    if key == '_id' or _.isFunction(obj[key])
      continue
    if _.isArray(value)
      ret[key] = visitSchemaArray(value, schema[key], func)
    else if _.isObject(value) and not _.isFunction(value)
      ret[key] = visitSchemaObject(value, schema[key], func)
    else
      ret[key] = func(value, schema[key])
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

    valid = visitSchemaObject @, schema, (x, node)->
      if node.optional == true
        return true
      klass = node.type[0] or node.type
      #if klass
      if klass is String
        return _.isString(x)
      else if klass is Number
        return _.isNumber(x)
      else if klass is Boolean
        return _.isBoolean(x)
      else if klass is Date
        return _.isDate(x)
      else if x instanceof klass
        return true
      return false

    if not _.all(_.flatten valid)
      throw 'not all are valid'

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

soop = {}
soop.Base  = Base
soop.properties = properties

