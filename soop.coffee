visitSchemaArray = (array, schema, func, out, flatten, path)->
  ret = []

  if not schema.type
    schema.type = schema
  base = path
  for value, i in array
    path = base + ':' + i
    if _.isArray(value)
      ret.push visitSchemaArray(value, schema.type[0], func, out, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret.push new schema.type[0](visitSchemaObject(value, schema.type[0].schema, func, out, flatten, path))
    else
      if value instanceof Base or value instanceof InLine
        ret.push value
        func(value, schema, out, flatten, path)
        visitSchemaObject(value, schema.type[0].schema, func, out, flatten, path)
      else
        ret.push func(value, schema, out, flatten, path)
  ret


visitSchemaObject = (obj, schema, func, out, prev, flatten, path) ->

  base = path or ''
  ret = {}

  prev = out

  for key, value of obj
    console.log obj, key, value
    if not _.isFunction(value)
      out[key] = {}

    path = base + ':' + key
    if _.isFunction(obj[key]) #or key == '_id'
      continue
    if key == '_id'
      #ret[key] =
      func(value, {type: String}, out, prev, key, flatten, path)
    else if _.isArray(value)
      ret[key] = visitSchemaArray(value, schema[key], func, out, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)

      ret[key] = new schema[key].type(visitSchemaObject(value, schema[key].type.schema, func, out[key], prev, flatten, path))
      func(value, schema[key], out[key], prev, key, flatten, path) # #########################################
    else if schema[key] and schema[key].type instanceof Base and _.isString(value)
      console.log '***************', value
      ret[key] = new schema[key].type(visitSchemaObject({key:value}, schema[key].type.schema, func, out[key], prev, flatten, path))
      func(value, schema[key], out[key], prev, key, flatten, path) # #########################################
    else
      if value instanceof Base or value instanceof InLine
        ret[key] = value
        func(value, schema[key], out[key], prev, key, flatten, path) # #########################################
        console.log '***************>', value
        visitSchemaObject(value, schema[key].type.schema, func, {}, {}, flatten, path)
      else
        ret[key] = value
        func(value, schema[key], out[key], prev, key, flatten, path)

  for key of schema
    if key not in _.keys(obj)
      ret[key] = undefined
      func(undefined, schema[key], out, prev, key, flatten, base + ':' + key)

  return ret

class Base
  constructor: (args, doFindOne)->
    #console.log 'constructor', args
    if _.isString(args)
      args = {_id: args}
    if doFindOne is undefined
      doFindOne = true

    if args is undefined then args = {}
    if args._id
      @_id = args._id
      if doFindOne
        args = @constructor.collection.findOne(args._id)

    schema = @constructor.schema
    console.log '**************', args
    values = visitSchemaObject args, schema, (->), {}, {}

    for key, value of values
      if not _.isFunction(value)
        @[key] = value

  @findOne: (selector)->
    klass = @
    #if selector is undefined or selector is null
    #  selector = {}
    #new klass(@collection.findOne(selector), false)
    new klass(selector, true)

  save: ->
    doc = {}
    schema = @constructor.schema

    if false
      recip = {}
      visitSchemaObject @, schema, ( (x, node, out, flatten, path)->
        if x is undefined and node.optional == true
          flatten[path] = true
          return x
        klass = node.type[0] or node.type
        if klass is String
          if _.isString(x) then flatten[path] = true else flatten[path] = false
        else if klass is Number
          if _.isNumber(x) then flatten[path] = true else flatten[path] = false
        else if klass is Boolean
          if _.isBoolean(x) then flatten[path] = true else flatten[path] = false
        else if klass is Date
          if _.isDate(x) then flatten[path] = true else flatten[path] = false
        else if x instanceof klass
          return x
        else
          flatten[path] = false
        return x
      ), {}, {}, recip #, false

      console.log 'recip', recip
      if not _.all(_.flatten(_.values(recip)))
        throw 'not all are valid'
    console.log '**************************************************************************'
    doc = {}
    visitSchemaObject @, schema,((x, node, out, prev, key, flatten, path) ->

      if x instanceof Base
        if not x._id
          x.save()
        prev[key] =  x._id
      else if x instanceof InLine
        for attr, value of x
          if value instanceof Base
            if not value._id
              value.save()
            out[attr] = value._id
          else if value instanceof InLine
            out[attr] = value
          else
            out[attr] = value
      else
        prev[key] = x
       ), doc, @

    if @_id is undefined
      console.log 'doc en insert', doc
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(@_id, {$set: doc})

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
#soop.properties = properties
soop.InLine = InLine