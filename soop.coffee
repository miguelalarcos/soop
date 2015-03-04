###
save_array = (array, schema)->
  ret = []
  for v in array
    if _.isArray(v)
      ret.push save_array(v, schema[0])
    else if _.isObject(v) and not (v instanceof Base)
      ret.push save(v, schema[0])
    else if v instanceof Base
      save(v, schema[0])
      ret.push v._id
    else
      ret.push v
  return ret

save = (obj, schema)->
  ret = {}
  if _.isArray(obj)
    return save_array(obj, schema.type)
  #if _.isObject(obj) and schema.prototype instanceof Base
  #  z = new schema(obj)
  #  z._save(obj)
  #  return z._id

  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      #return save_array(value, schema[key].type)
      ret[key] = save_array(value, schema[key].type)
    else if _.isObject(value) and not (value instanceof Base)
      doc = save(value, schema[key].type.schema)
      ret[key] = doc
    else if _.isObject(value) and value instanceof Base
      doc = save(value, schema[key].type.schema)
      ret[key] = value._id # doc._id?
    else
      ret[key] = value

  if obj instanceof Base
    obj._save(ret)
    ret._id = obj._id
  return ret

createArray = (value, schema)->
  ret = []
  for v in value
    if _.isArray(v)
      ret.push createArray(v, schema[0])
    else
      ret.push create(v, schema[0])
  ret

create = (obj, schema)->
  if _.isArray(obj)
    return createArray(obj, schema.type)
  if _.isString(obj)
    console.log schema
    return new schema(obj)
  if obj instanceof Base
    ret = obj
  else
    ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      ret[key] = createArray(value, schema[key])
    else if _.isObject(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(value)
    else
      ret[key] = value
  return ret

class Base
  constructor: (args, doFindOne)->
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
    values = create args, schema

    for key, value of values
      if not _.isFunction(value)
        @[key] = value

  _save: (doc) ->
    if doc._id is undefined
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(doc._id, {$set: doc})

  save: ->
    save(@, @constructor.schema, @constructor.collection)

  @findOne: (_id) ->
    new @({_id: _id})

class InLine
  constructor: (args)->
    schema = @constructor.schema
    for key, value of args
      if _.isFunction(value)
        continue
      klass = schema[key].type
      if klass.prototype instanceof InLine or klass.prototype instanceof Base
        @[key] = new klass value
      else if _.isArray(value)
        @[key] = createArray value, schema[key].type
      else
        @[key] = value

soop = {}
soop.Base  = Base
#soop.properties = properties
soop.InLine = InLine
###

save_array = (array, schema)->
  ret = []
  for v in array
    if _.isArray(v)
      ret.push save_array(v, schema[0])
    else if _.isObject(v) and not (v instanceof Base)
      ret.push save(v, schema[0])
    else if v instanceof Base
      save(v, schema[0])
      ret.push v._id
      console.log 'ENTRO', v._id
    else
      ret.push v
  console.log ret
  return ret

save = (obj, schema)->

  ret = {}
  #if _.isArray(obj)
  #  return save_array(obj, schema.type)

  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      ret[key] = save_array(value, schema[key].type)
      console.log key, ret[key]
      continue
    #else if _.isObject(value) and not (value instanceof Base)
    #  doc = save(value, schema[key].type.schema)
    #  ret[key] = doc
    if value instanceof Base
      doc = save(value, schema[key].type.schema)
      ret[key] = doc._id #value._id
    if value instanceof InLine # else if no funciona, averiguar por qué
      doc = save(value, schema[key].type.schema)
      ret[key] = doc
    else
      ret[key] = value

  if obj instanceof Base
    obj._save(ret)
    ret._id = obj._id
  return ret


createArray = (value, schema)->
  ret = []
  for v in value
    if _.isArray(v)
      ret.push createArray(v, schema[0])
    else
      if schema[0].prototype instanceof Base or schema[0].prototype instanceof InLine
        console.log '2) llamo a create con schema', schema
        ret.push new schema[0](create(v, schema))
      else
        ret.push v #create(v, schema[0])
  ret

create = (obj, schema)->
  #if _.isArray(obj)
  #  return createArray(obj, schema.type)

  if _.isString(obj)
    console.log '************************* schema', obj, schema, schema[0]
    return new (schema[0])({_id: obj})

  #if obj instanceof Base
  #  ret = obj
  #else
  #  ret = {}
  ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      ret[key] = createArray(value, schema[key])
    else if _.isObject(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(value, false)
    else
      ret[key] = value
  return ret

class Base
  constructor: (args, doFindOne)->
    doFindOne = doFindOne or true
    args = args or {}

    if args._id
      @_id = args._id
      if doFindOne
        args = @constructor.collection.findOne(args._id)

    schema = @constructor.schema
    console.log '1) llamo a create con schema', schema
    values = create args, schema

    for key, value of values
      if not _.isFunction(value)
        @[key] = value

  _save: (doc) ->
    if doc._id is undefined
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(doc._id, {$set: doc})

  save: ->
    save(@, @constructor.schema)

  @findOne: (_id) ->
    new @({_id: _id})

class InLine
  constructor: (args)->
    schema = @constructor.schema
    for key, value of args
      #if _.isFunction(value)
      #  continue
      klass = schema[key].type
      if klass.prototype instanceof InLine or klass.prototype instanceof Base
        @[key] = new klass value
      else if _.isArray(value)
        @[key] = createArray value, klass #schema[key].type
      else
        @[key] = value

soop = {}
soop.Base  = Base
#soop.properties = properties
soop.InLine = InLine
