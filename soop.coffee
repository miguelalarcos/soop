_validate = (x, klass)->
  if x is undefined and klass.optional == true
    return [true, '']
  if x is undefined
    return [false, 'value undefined']
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
  else
    if x instanceof klass
      {v:true, m:''}
    else
      {v:false,  m: x + ' must be of type ' + klass}

validateArray = (value, schema)->
  ret = []
  for v in value
    if _.isArray(v) #
      ret.push validateArray(v, schema[0]) #
    else if v instanceof Base or v instanceof InLine
      ret.push _validate(v, schema[0])
      ret.push validate(v, schema[0])
    else
      ret.push _validate(v, schema[0])
  return ret

validate = (obj, schema) ->
  ret = []
  obj2 = {}
  for key in _.keys(schema)
    if key not in _.keys(obj)
      obj2[key] = undefined
    else
      obj2[key] = obj[key]
  for key, value of obj2
    if _.isFunction(value) or key == '_id' or key == '_dirty'
      continue
    if value instanceof Base or value instanceof InLine
      r = validate(value, schema[key].type.schema)
      ret = _.flatten(ret.concat(r))
    else if _.isArray(value)
      validateArray(value, schema[key].type)
    else
      if _.isFunction(schema)
        ret.push _validate(value, schema)
      else
        ret.push _validate(value, schema[key].type)

  return ret


save_array = (array, schema)->
  ret = []
  toBDD = []
  for v in array
    if _.isArray(v)
      [docs, docs2] = save_array(v, schema[0])
      ret.push docs
      toBDD.push docs2
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
    if _.isFunction(value) or key == '_id' or key == '_dirty'
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
      klass = schema[0] or schema
      if klass.prototype instanceof Base or klass.prototype instanceof InLine
        doc = create(v, klass)
        ret.push new klass(doc)
      else
        ret.push v
      #if schema[0].prototype instanceof Base or schema[0].prototype instanceof InLine
      #  doc = create(v, schema[0])
      #  ret.push new schema[0](doc)
      #else
      #  ret.push v
  ret

create = (obj, schema)->
  if _.isString(obj)
    return new (schema)({_id: obj})

  ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id' or key == '_dirty'
      continue
    if _.isArray(value)
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
    @_dirty = []
    doFindOne = doFindOne or true
    args = args or {}

    if args._id
      @_id = args._id
      if doFindOne
        args = @constructor.collection.findOne(args._id)

    schema = @constructor.schema
    if _.isString(args)
      values = create args, @constructor
    else
      values = create args, schema

    for key, value of values
      if not _.isFunction(value)
        @[key] = value

  _save: (doc) ->
    #if doc._id is undefined
    if @_id is undefined
      @_id = @constructor.collection.insert(doc)
      @_dirty = []
    else
      out = getMongoSet(@)
      for elem in out
        if elem.object._dirty.length == 0
          continue
        doc = {}
        for pv in elem.paths
          doc[pv.path[1..]] = pv.value
        if elem.object.constructor.collection
          elem.object.constructor.collection.update(elem.object._id, {$set: doc})
          elem.object._dirty = []

  save: ->
    save(@, @constructor.schema)
    #save(new @constructor, @.constructor.schema, true)

  @findOne: (_id) ->
    new @({_id: _id})

class InLine
  constructor: (args)->
    @_dirty = []
    schema = @constructor.schema
    for key, value of args
      klass = schema[key].type
      if klass.prototype instanceof InLine or klass.prototype instanceof Base
        @[key] = new klass value
      else if _.isArray(value)
        @[key] = createArray value, klass
      else
        @[key] = value

getter_setter = (obj, attr) ->
  get: -> obj[attr]
  set: (value) ->
    obj[attr] = value
    if attr not in obj._dirty
      obj._dirty.push attr

properties = (obj) ->
  if obj is undefined
    return
  for attr, value of obj.constructor.schema
    if _.isArray(value.type) and obj[attr] isnt undefined
      for v in obj[attr]
        properties(v)
      #return
    else if (value.type.prototype instanceof Base or value.type.prototype instanceof InLine) and obj[attr] isnt undefined
      properties(obj[attr])
    else
      Object.defineProperty obj, 'prop_' + attr, getter_setter(obj, attr)

_getMongoSet = (prefix, obj, ret, baseParent) ->

  if _.isArray(obj)
    if obj.length > 0
      for v,i in obj #[0].constructor.schema # obj
        if v instanceof Base or v instanceof InLine
          #if obj[i] is undefined
          #  return
          ret.push { object: v, paths: [] }
          _getMongoSet(prefix + '.' + i, v, ret, baseParent)
        else
          null
  else
    if obj is undefined
      return
    for attr, value of obj.constructor.schema
      if _.isArray(value.type)
        _getMongoSet(prefix + '.' + attr, obj[attr], ret, obj)
      else if value.type.prototype instanceof Base or value.type.prototype instanceof InLine
        if obj[attr] is undefined
          continue
        if value.type.prototype instanceof InLine
          ret.push { object: baseParent, paths: [] }
          _getMongoSet(prefix + '.' + attr, obj[attr], ret, baseParent)
        else
          ret.push { object: obj[attr], paths: [] }
          _getMongoSet(prefix + '.' + attr, obj[attr], ret, obj)
      else if attr in obj._dirty
        for dct in ret
          if obj instanceof InLine
            comp = baseParent
          else
            comp = obj
          if _.isEqual(dct.object, comp)
            dct.paths.push {path: prefix + '.' +attr, value: obj[attr]}
            break

getMongoSet = (obj) ->
  out = [{object: obj, paths: []}]
  _getMongoSet('', obj, out, obj)
  return out


soop = {}
soop.Base  = Base
soop.properties = properties
soop.InLine = InLine
soop.validate = validate
soop.getMongoSet = getMongoSet
