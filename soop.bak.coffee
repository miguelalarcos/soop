#
_visitSchemaArray = (array, schema, func, flatten, path)->
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
        func(value, schema, flatten, path)
        visitSchemaObject(value, schema.type[0].schema, func, flatten, path)
      else
        ret.push func(value, schema, flatten, path)
  ret

_visitSchemaObject = (obj, schema, func, flatten, path) ->
  base = path or ''
  ret = {}

  for key, value of obj
    path = base + ':' + key
    if _.isFunction(obj[key]) #or key == '_id'
      continue
    if key == '_id'
      ret[key] = func(value, {type: String}, flatten, path)
    else if _.isArray(value)
      ret[key] = visitSchemaArray(value, schema[key], func, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(visitSchemaObject(value, schema[key].type.schema, func, flatten, path))
    else
      if value instanceof Base or value instanceof InLine
        ret[key] = value
        func(value, schema[key], flatten, path) # #########################################
        visitSchemaObject(value, schema[key].type.schema, func, flatten, path)
      else
        ret[key] = func(value, schema[key], flatten, path)

  for key of schema
    if key not in _.keys(obj)
      ret[key] = undefined
      func(undefined, schema[key], flatten, base + ':' + key)

  return ret
#
visitSchemaArray = (array, schema, func, replace, flatten, path)->
  ret = []
  console.log '===========visitSchemaArray', array
  if not schema.type
    schema.type = schema
  base = path
  for value, i in array
    path = base + ':' + i
    if _.isArray(value)
      console.log 'is array', value
      ret.push visitSchemaArray(value, schema.type[0], func, replace, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) #and not (value instanceof Base) and not (value instanceof InLine)
      console.log '* * * is object', value, replace
      #if value instanceof Base or value instanceof InLine
      #  ret.push value
      #  visitSchemaObject(value, schema.type[0].schema, func, flatten, path)
      #else
      z = visitSchemaObject(value, schema.type[0].schema, func, replace, flatten, path)
      console.log 'z', z
      x = func(z, schema, flatten, path)
      console.log '* * *ret.push x', x
      ret.push x
    else
      console.log value, schema
      ret.push func(value, schema, flatten, path)

  console.log 'return array', ret
  ret

visitSchemaObject = (obj, schema, func, replace, flatten, path) ->
  console.log 'visitSchemaObject', obj
  base = path or ''
  ret = {}

  for key, value of obj
    path = base + ':' + key
    if _.isFunction(obj[key]) or key == '_id'
      continue
    else if _.isArray(value)
      if replace
        obj[key] = visitSchemaArray(value, schema[key], func, replace, flatten, path)
      else
        ret[key] = visitSchemaArray(value, schema[key], func, replace, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) #and ((value instanceof Base) or (value instanceof InLine))
      if replace
        obj[key] = func(visitSchemaObject(value, schema[key].type.schema, func, replace, flatten, path),schema[key], flatten, path)
      else
        ret[key] = func(visitSchemaObject(value, schema[key].type.schema, func, replace, flatten, path),schema[key], flatten, path)
    else
      if replace
        obj[key] = func(value, schema[key], flatten, path)
      else
        ret[key] = func(value, schema[key], flatten, path)

  for key of schema
    if key not in _.keys(obj)
      if replace then obj[key] = undefined
      func(undefined, schema[key], flatten, base + ':' + key)

  if not replace
    return ret
  return obj

class Base
  constructor: (args, doFindOne)->
    if doFindOne is undefined
      doFindOne = true

    if args is undefined then args = {}
    if args._id
      @_id = args._id
      if doFindOne
        args = @constructor.collection.findOne(args._id)

    schema = @constructor.schema

    values = visitSchemaObject args, schema, ((x, node)->
      klass = node.type[0] or node.type
      if klass and klass.prototype instanceof Base and not (x instanceof  Base)
        new klass x, doFindOne
      else if klass and klass.prototype instanceof InLine and not (x instanceof InLine)
        new klass x
      else
        x), true

    for key, value of values
      if not _.isFunction(value)
        @[key] = value


  @find : (selector) ->
    klass = @
    if selector is undefined or selector is null
      selector = {}
    (new klass(doc, false) for doc in @collection.find(selector).fetch())

  @findOne: (selector)->
    klass = @
    #if selector is undefined or selector is null
    #  selector = {}
    #new klass(@collection.findOne(selector), false)
    new klass(selector, true)

  clone: ->
    doc = visitSchemaObject @, @constructor.schema,((x, node) ->
      console.log 'x->', x
      if _.isObject(x)# instanceof Base or x instanceof InLine
        klass = node.type[0] or node.type
        args = {}
        for k,v of x
          args[k] = v
        console.log '------------>args', args, klass
        new klass args
      else
        x
    ), false
    return doc

  save: ->
    doc = {}
    schema = @constructor.schema

    recip = {}
    valid = visitSchemaObject @, schema, ( (x, node, out, path)->
      if x is undefined and node.optional == true
        out[path] = true
        return x
      klass = node.type[0] or node.type
      if klass is String
        if _.isString(x) then out[path] = true else out[path] = false
      else if klass is Number
        if _.isNumber(x) then out[path] = true else out[path] = false
      else if klass is Boolean
        if _.isBoolean(x) then out[path] = true else out[path] = false
      else if klass is Date
        if _.isDate(x) then out[path] = true else out[path] = false
      else if x instanceof klass
        return x
      else
        out[path] = false
      return x
    ), recip, false

    console.log 'recip', recip
    if not _.all(_.flatten(_.values(recip)))
      throw 'not all are valid'

    doc = visitSchemaObject @, schema,((x, node) ->
      klass = node.type[0] or node.type
      if klass
        #if klass.prototype instanceof Base and x instanceof Base and not x._id
        if x instanceof Base and not x._id
          x.save()
          return x #._id
        else if klass.prototype instanceof InLine
          for attr, value of x
            if value instanceof Base and not value._id
              value.save()
          return x
        else
          x
      return x), false

    #delete doc.constructor
    #delete doc.save
    if @_id is undefined
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(@_id, {$set: doc})

properties = (self, props) -> Object.defineProperties self.prototype, props

class InLine
  constructor: (args)->
    schema = @constructor.schema
    for key, value of args
      if _.isFunction(value)
        continue
      klass = schema[key].type
      if klass.prototype instanceof InLine or klass.prototype instanceof Base
        @[key] = new klass value
      else
        @[key] = value

soop = {}
soop.Base  = Base
soop.properties = properties
soop.InLine = InLine

