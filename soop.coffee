_validate = (x, klass)->
  if x is undefined and klass.optional == true
    return [true, '']
  if klass is String
    if _.isString(x)
      {v:true, m:''}
    else
      {v:false, m: x + ' must be String'}
  else if klass is Number
    if _.isNumber(x)
      {v:true, m:''}
    else
      {v:false. x + ' must be Number'}
  else if klass is Boolean
    if _.isBoolean(x)
      {v:true, m:''}
    else
      {v:false,  m: x + ' must be a Boolean'}
  else if klass is Date
    if _.isDate(x)
      {v:true, m:''}
    else
      {v:false,  m: x + ' must be a Date'}
  else if x instanceof klass
    {v:true, m:''}
  else
    {v:false,  m: x + ' must be of type ' + klass}

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
          ret.push _validate(v, schema[key].type[0])
          ret.push validate(v, schema[key].type[0].schema)
        else
          ret.push _validate(v, schema[key].type[0])
    else
      ret.push _validate(value, schema[key].type)
  return ret


save_array = (array, schema)->
  ret = []
  toBDD = []
  for v in array
    if _.isArray(v)
      docs = save_array(v, schema[0])
      ret.push docs
      toBDD.push docs
    else if _.isObject(v) and not (v instanceof Base)
      [doc, doc2 ]= save(v, schema[0])
      ret.push doc
      toBDD.push doc2
    else if v instanceof Base
      save(v, schema[0])
      ret.push v
      toBDD.push v._id
    else
      ret.push v
      toBDD.push v
  return [ret, toBDD]

save = (obj, schema)->
  ret = {}
  toBDD = {}

  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      [ret[key], toBDD[key]] = save_array(value, schema[key].type)
    else if value instanceof Base
      [doc, nothing] = save(value, schema[key].type.schema)
      toBDD[key] = doc._id
      ret[key] = doc
    else if value instanceof InLine
      [doc, doc2] = save(value, schema[key].type.schema)
      ret[key] = doc
      toBDD[key] = doc2
    else
      ret[key] = value
      toBDD[key] = value

  if obj instanceof Base
    obj._save(toBDD)
    ret._id = obj._id
  return [ret, toBDD]


createArray = (value, schema)->
  ret = []
  for v in value
    if _.isArray(v)
      ret.push createArray(v, schema[0])
    else
      if schema[0].prototype instanceof Base or schema[0].prototype instanceof InLine
        console.log 'schema que viaja hacia create', v, schema
        doc = create(v, schema[0])
        ret.push new schema[0](doc)
      else
        ret.push v
  ret

create = (obj, schema)->

  if _.isString(obj)
    console.log 1, obj, schema
    z = new (schema)({_id: obj})
    console.log 2
    return z

  ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id'
      continue
    if _.isArray(value)
      console.log 'llamamos a createArray con shcema y key', schema, key
      ret[key] = createArray(value, schema[key])
    else if _.isObject(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret[key] = new schema[key].type(value, false)
    else if _.isString(value) and schema[key] and schema[key].type.prototype instanceof Base
      ret[key] = new (schema[key].type)({_id: value})
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
    if _.isString(args)
      console.log 'llamo desde Base a create con args y schema', args, @constructor
      values = create args, @constructor
    else
      values = create args, schema

    for key, value of values
      if not _.isFunction(value)
        @[key] = value

  _save: (doc) ->
    if doc._id is undefined
      console.log 'DOC to be inserted', doc
      @_id = @constructor.collection.insert(doc)
    else
      @constructor.collection.update(doc._id, {$set: doc})

  save: ->
    save(@, @constructor.schema)
    #save(new @constructor, @.constructor.schema, true)

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
        console.log 'llamo a createArray con value, klass', value, klass
        #for v, i in value
        #  @[key] = []
        #  @[key][i] = create value, klass
        @[key] = createArray value, klass
      else
        @[key] = value

soop = {}
soop.Base  = Base
#soop.properties = properties
soop.InLine = InLine
soop.validate = validate

