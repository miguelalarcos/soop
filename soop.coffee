visitSchemaArray = (array, schema, func, flatten, path)->
  ret = []

  if not schema.type
    schema.type = schema
  base = path
  for value, i in array
    path = base + ':' + i
    if _.isArray(value)
      ret.push visitSchemaArray(value, schema.type[0], func, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret.push new schema.type[0](visitSchemaObject(value, schema.type[0].schema, func, flatten, path))
    else
      if value instanceof Base or value instanceof InLine
        ret.push value
        visitSchemaObject(value, schema.type[0].schema, func, flatten, path)
      else
        ret.push func(value, schema, flatten, path)
  ret

visitSchemaObject = (obj, schema, func, flatten, path) ->
  base = path or ''
  ret = {}

  for key, value of obj
    path = base + ':' + key
    if key == '_id' or _.isFunction(obj[key])
      continue
    if _.isArray(value)
      ret[key] = visitSchemaArray(value, schema[key], func, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(visitSchemaObject(value, schema[key].type.schema, func, flatten, path))
    else
      if value instanceof Base or value instanceof InLine
        ret[key] = value
        visitSchemaObject(value, schema[key].type.schema, func, flatten, path)
      else
        ret[key] = func(value, schema[key], flatten, path)

  for key of schema
    if key not in _.keys(obj)
      ret[key] = undefined
      console.log 'key not in', key, schema
      func(undefined, schema[key], flatten, base + ':' + key)

  return ret

class Base
  constructor: (args, doFindOne)->
    console.log 'constructor', args
    if doFindOne is undefined
      doFindOne = true

    if args is undefined then args = {}
    if args._id
      @_id = args._id
      if doFindOne
        args = @constructor.collection.findOne(args._id)
    #else
    #  @_id = null

    schema = @constructor.schema

    values = visitSchemaObject args, schema, (x, node)->
      # pensar en dejar solo la linea de arriba
      klass = node.type[0] or node.type
      if klass and klass.prototype instanceof Base
        console.log '---------new Base', klass
        new klass({_id: x})
      else if klass and klass.prototype instanceof InLine
        console.log '-------new Inline', klass
        new klass x
      else
        console.log '----------else', x
        x

    for key, value of values
      @[key] = value


  @find : (selector) ->
    klass = @
    if selector is undefined or selector is null
      selector = {}
    (new klass(doc, false) for doc in @collection.find(selector).fetch())

  @findOne: (selector)->
    klass = @
    if selector is undefined or selector is null
      selector = {}
    new klass(@collection.findOne(selector), false)

  save: ->
    console.log 'save'
    doc = {}
    schema = @constructor.schema

    #s = visitSchemaObject schema,{}, (x)-> x #clone the schema
    #ss = new SimpleSchema s
    #ctx = ss.newContext()

    recip = {}
    valid = visitSchemaObject @, schema, ( (x, node, out, path)->
      if x is undefined and node.optional == true
        out[path] = true
        return
      klass = node.type[0] or node.type
      console.log x, klass
      if klass is String
        if _.isString(x) then out[path] = true else out[path] = false
      else if klass is Number
        if _.isNumber(x) then out[path] = true else out[path] = false
      else if klass is Boolean
        if _.isBoolean(x) then out[path] = true else out[path] = false
      else if klass is Date
        if _.isDate(x) then out[path] = true else out[path] = false
      #else if x instanceof klass
      #  out[path] = true
      else
        out[path] = false
    ), recip

    console.log 'recip', recip
    if not _.all(_.flatten(_.values(recip)))
      throw 'not all are valid'

    doc = visitSchemaObject @, schema, (x, node) ->
      klass = node.type[0] or node.type
      if klass
        if klass.prototype instanceof Base
          x.save()
          x._id
        else if klass.prototype instanceof InLine
          for attr, value of x
            if value instanceof Base
              value.save()
          x
        else
          x

    if @_id is undefined
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(@_id, {$set: doc})

properties = (self, props) -> Object.defineProperties self.prototype, props

class InLine
  constructor: (args)->
    console.log 'constructor', args
    schema = @constructor.schema
    for key, value of args
      if _.isFunction(value)
        continue
      klass = schema[key].type
      #if klass.prototype instanceof InLine or klass.prototype instanceof Base
      #  @[key] = new klass value
      #else
      @[key] = value

soop = {}
soop.Base  = Base
soop.properties = properties
soop.InLine = InLine

