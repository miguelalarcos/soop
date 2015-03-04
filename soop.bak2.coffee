visitSchemaArray = (array, schema, func, out, prev, flatten, path)->
  console.log 'entramos en visitSchemaArray', out, prev
  ret = []
  if not schema.type
    schema.type = schema
  base = path
  for value, i in array
    path = base + ':' + i
    if _.isArray(value)
      console.log 'is array otra vez'
      context = []
      out.push context
      ret.push visitSchemaArray(value, schema.type[0], func, context, out, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)
      console.log 'NEW'
      z = new schema.type[0](visitSchemaObject(value, schema.type[0].schema, func, out, prev, flatten, path))
      ret.push z
      context = {}
      out.push context
      func(z, schema, context, out, '', flatten, path)
    else
      if value instanceof Base or value instanceof InLine
        ret.push value
        func(value, schema, out, prev, '', flatten, path)
        visitSchemaObject(value, schema.type[0].schema, func, out, prev, flatten, path)
      else
        ret.push func(value, schema, out, prev, '', flatten, path)
  ret


visitSchemaObject = (obj, schema, func, out, prev, flatten, path) ->

  base = path or ''
  ret = {}

  prev = out

  for key, value of obj

    if not _.isFunction(value)
      out[key] = {}

    path = base + ':' + key
    if _.isFunction(obj[key]) #or key == '_id'
      continue
    if key == '_id'
      #ret[key] =
      func(value, {type: String}, out, prev, key, flatten, path)
    else if _.isArray(value)
      console.log 'llamamos a is array'
      out[key] = []
      ret[key] = visitSchemaArray(value, schema[key], func, out[key], prev, flatten, path)
    else if _.isObject(value) and not _.isFunction(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(visitSchemaObject(value, schema[key].type.schema, func, out[key], prev, flatten, path))
      func(value, schema[key], out[key], prev, key, flatten, path)
    else if schema[key] and schema[key].type instanceof Base and _.isString(value)
      ret[key] = new schema[key].type(visitSchemaObject({key:value}, schema[key].type.schema, func, out[key], prev, flatten, path))
      func(value, schema[key], out[key], prev, key, flatten, path)
    else if value instanceof Base or value instanceof InLine
      ret[key] = value
      func(value, schema[key], out[key], prev, key, flatten, path)
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
      console.log 'FLAG', x, prev
      if x instanceof Base
        if not x._id
          x.save()
        if _.isArray(prev)
          prev.push x._id
        else
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
      console.log 'INSERT DOC', doc
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