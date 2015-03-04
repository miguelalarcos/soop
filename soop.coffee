findOne = ()->


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
  console.log '--->save', obj, schema
  ret = {}
  if _.isArray(obj)
    console.log 'ALERTA0', obj
    return save_array(obj, schema.type)
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      console.log 'ALERTA', key, value
      #return save_array(value, schema[key].type)
      ret[key] = save_array(value, schema[key].type)
    else if _.isObject(value) and not (value instanceof Base)
      doc = save(value, schema[key].type.schema)
      ret[key] = doc
      console.log 'ret1', ret, value
    else if _.isObject(value) and value instanceof Base
      doc = save(value, schema[key].type.schema)
      ret[key] = value._id # doc._id?
      console.log 'ret2', ret
    else
      ret[key] = value
      console.log 'ret3', ret

  if obj instanceof Base
    console.log '_save', obj, ret
    obj._save(ret)
  return ret

createArray = (value, schema)->

  ret = []
  for v in value
    ret.push create(v, schema) # ??
  ret

create = (obj, schema)->

  if _.isArray(obj)

    createArray(obj, schema.type)
  ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)

      createArray(value, schema[key])
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
      else
        @[key] = value

soop = {}
soop.Base  = Base
#soop.properties = properties
soop.InLine = InLine