_validate = (x, klass)->
  if x is undefined and klass.optional == true
    return true
  if klass is String
    if _.isString(x) then true else false
  else if klass is Number
    if _.isNumber(x) then true else false
  else if klass is Boolean
    if _.isBoolean(x) then true else false
  else if klass is Date
    if _.isDate(x) then true else false
  else
    false

validate = (obj, schema) ->
  ret = []
  obj2 = {}
  for key in _.keys(schema)
    if key not in _.keys(obj)
      obj2[key] = undefined
    else
      obj2[key] = obj[key]
  for key, value of obj2
    if _.isFunction(value) or key == '_id'
      continue
    if value instanceof Base or value instanceof InLine
      r = validate(value, schema[key].type.schema)
      ret = _.flatten(ret.concat(r))
    else if _.isArray(value)
      for v in value
        if v instanceof Base or v instanceof InLine
          ret.push validate(v, schema[key].type[0].schema)
        else
          ret.push _validate(v, schema[key].type[0])
    else
      ret.push _validate(value, schema[key].type)
  return ret


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

  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      ret[key] = save_array(value, schema[key].type)
    else if value instanceof Base or value instanceof InLine
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
        ret.push new schema[0](create(v, schema))
      else
        ret.push v
  ret

create = (obj, schema)->

  if _.isString(obj)
    return new (schema[0])({_id: obj})

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
      klass = schema[key].type
      if klass.prototype instanceof InLine or klass.prototype instanceof Base
        @[key] = new klass value
      else if _.isArray(value)
        @[key] = createArray value, klass
      else
        @[key] = value

soop = {}
soop.Base  = Base
#soop.properties = properties
soop.InLine = InLine
soop.validate = validate
