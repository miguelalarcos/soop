save_array = (array, schema)->
  console.log 'save_array', schema
  ret = []
  for v, i in array
    if _.isArray(v)
      ret[i] = save_array(v, schema[0])
    else
      save(v, schema[0])
  return ret

save = (obj, schema)->
  console.log 'OBJ', obj
  ret = {}
  if _.isArray(obj)
    return save_array(obj, schema.type)
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      return save_array(value, schema[key].type)
    else if _.isObject(value) and not (value instanceof Base)
      doc = save(value, schema[key].type.schema)
      ret[key] = doc
      console.log 'ret[key] = value', key, value
    else if _.isObject(value) and value instanceof Base
      save(value, schema[key].type.schema)
      console.log 'ret[key] = value._id', key, value, value._id
      ret[key] = value._id
    else
      ret[key] = value

  if obj instanceof Base
    console.log 'obj._save(ret)', ret
    obj._save(ret)
  return ret

create = (obj, schema)->
  ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isObject(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(value)
    if _.isArray(value)
      ret = []
      for v in value
        ret.push create(v, schema[key])
      return ret
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
    doc = save(@, @constructor.schema, @constructor.collection)
    @_save(doc)


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