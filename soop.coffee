array = (v) ->
  v.set = setterArray(v)
  #v._setted = true
  return v

#isValid = (obj) ->
#  _.all( (x.v for x in soop.validate(obj, obj.constructor.schema ) ))

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
    keys_obj_without_ = (w[1..] for w in _.keys(obj))
    if key not in keys_obj_without_
      obj2[key] = undefined
    else
      obj2[key] = obj[key]
  for key, value of obj2
    if _.isFunction(value) or key == '_id' or key == '_dirty' or key == '_propertyCreated'
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
      toBDD.push docs2 # ### cloneAndFilter???
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

clone = (obj, klass) ->

  if _.isArray(obj)
    ret = []
    for v in obj
      ret.push clone(v)
  else if _.isObject(obj)
    ret = {}
    for k,v of obj
      if _.isFunction(v) # or not /^_/.test(k)
        continue
      ret[k] = filter(clone(v))
      #if klass
      #  ret[k] = new klass(clone(v), true)
        #console.log 'flag'
      #  ret[k] = filter(clone(v))
      #else
      #  ret[k] = clone(v)
  else
    return obj
  return ret

filter = (obj) ->
  if not _.isObject(obj) or _.isArray(obj)
    return obj
  for attr in ['_propertyCreated', '_super__'] #, '_dirty']
    delete obj[attr]
  for attr, value of obj
    if _.isFunction(value)
      delete obj[attr]
      continue

    if /^_/.test(attr) and attr != '_id' and attr != '_dirty' and attr != '_klass'
    # if attr != '_id' and attr != '_dirty'
      obj[attr[1..]] = obj[attr]
      delete obj[attr]
  return obj

save = (obj, schema)->
  ret = {}
  toBDD = {}

  for key, value of obj
    if not _.isFunction(value) and key != '_id' and key != '_dirty' and key != '_propertyCreated' and /^_/.test(key)
      key = key[1..]
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

  #toBDD = cloneAndFilter(obj.constructor, toBDD)
  toBDD = clone(toBDD, obj.constructor)
  toBDD._dirty = obj._dirty
  toBDD.constructor = obj.constructor
  if obj instanceof Base
    toBDD._klass = 'Base'
  else if obj instanceof InLine
    toBDD._klass = 'InLine'
  if obj._id
    toBDD._id = obj._id

  if obj instanceof Base
    obj._save(toBDD, (x[1..] for x in obj._dirty) )
    ret._id = obj._id
  return [ret, toBDD]


createArray = (value, schema)->
  ret = []
  for v in value
    if _.isArray(v)
      ret.push createArray(v, schema[0])
    else
      klass = schema[0] or schema
      if _.isString(v) and klass.prototype instanceof Base
        ret.push new klass({_id: v})
      else if klass.prototype instanceof Base or klass.prototype instanceof InLine
        ret.push new klass(v) # sera necesario llamar a create??
      else
        ret.push v
        #doc = create(v, klass) # #####################################################
        #ret.push new klass(doc) # #####################################################

  return ret

create = (obj, schema)->

  if _.isString(obj)
    return new (schema)({_id: obj})

  ret = {}
  for key, value of obj
    if _.isFunction(value) or key == '_id' or key == '_dirty' or key == '_propertyCreated' or key == '_super__'
      continue
    if /^_/.test(key)
      key_ = key[1..]
    else
      key_ = key
    if key_ not in _.keys(schema)
      #console.log 'continue para key', key
      continue
    #console.log 'en create, schema', schema, key_
    if _.isArray(value)
      ret['_'+key_] = createArray(value, schema[key_])
    else if _.isObject(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret['_'+key_] = new schema[key_].type(value, false, false)
    else if _.isString(value) and schema[key_] and schema[key_].type.prototype instanceof Base
      ret['_'+key_] = new (schema[key_].type)({_id: value})
    else
      ret['_'+key_] = value
  return ret

class Base
  constructor: (args, noProperties, doFindOne)->

    #@_dirty = []
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


    if not noProperties and not @_propertyCreated
      properties(@)
      @_propertyCreated = true

    @_dirty = []

  isValid : ->
    _.all( (x.v for x in validate(@, @constructor.schema ) ))

  _save: (doc, dirty) ->

    if @_id is undefined
      @_id = @constructor.collection.insert(doc)
      @_dirty = []
    else
      out = getMongoSet(doc, dirty) # @
      for elem in out
        #if elem.object._dirty.length == 0
        #  continue
        doc = {}
        unset = {}
        for pv in elem.paths
          if pv.value is undefined
            unset[pv.path[1..]] = ''
          else if pv.path != '_id' and pv.path != '_dirty' and pv.path != '_propertyCreated'
            doc[pv.path[1..]] = pv.value

        if elem.object.constructor.collection and (not _.isEmpty(doc) or not _.isEmpty(unset))
          elem.object.constructor.collection.update(elem.object._id, {$set: doc, $unset: unset})
          elem.object._dirty = []
          @_dirty = []

  save: ->
    save(@, @constructor.schema)

  @findOne: (_id) ->
    new @({_id: _id})

class InLine
  constructor: (args, noProperties)->

    #@_dirty = []
    schema = @constructor.schema
    for key, value of args
      if key == '_dirty' or key == '_klass'
        continue
      klass = schema[key].type
      if _.isArray(value)

        @['_'+key] = createArray value, klass
      else if klass.prototype instanceof InLine or klass.prototype instanceof Base

        @['_'+key] = new klass value
      else

        @['_'+key] = value

    if not noProperties and not @_propertyCreated
      properties(@)
      @_propertyCreated = true
    @_dirty = []

  isValid : ->
    _.all( (x.v for x in validate(@, @constructor.schema ) ))

getter_setter = (obj, attr) ->
  get: -> obj[attr]
  set: (value) ->
    obj[attr] = value
    if attr not in obj._dirty
      obj._dirty.push attr

setterArray = (array) ->
  (index, value) ->
    array[index] = value

properties = (obj) ->
  if obj is undefined
    return
  for attr, value of obj.constructor.schema
    if _.isArray(value.type) and obj['_' + attr] isnt undefined
      Object.defineProperty obj, attr, getter_setter(obj, '_' + attr)
      obj[attr].set = setterArray(obj['_' + attr])
    else if (value.type.prototype instanceof Base or value.type.prototype instanceof InLine) and obj['_' + attr] isnt undefined
      Object.defineProperty obj, attr, getter_setter(obj, '_' + attr)
    else
      Object.defineProperty obj, attr, getter_setter(obj, '_' + attr)


_getMongoSet = (prefix, obj, ret, baseParent, baseDirty) -> # es posible usar baseParent._dirty?
  if _.isArray(obj)
    if obj.length > 0
      out = []
      ret.push {object: baseParent, paths: out}
      for v,i in obj
        if v._klass == 'Base' or v._klass == 'InLine'
          console.log 'entro', v, prefix + '.' + i
          ret.push { object: v, paths: [] }
          _getMongoSet(prefix + '.' + i, v, ret, baseParent, baseDirty)
        else
          out.push {path: prefix + '.' + i, value: v}
          baseDirty.push(prefix + '.' + i)
  else
    if obj is undefined
      return
    for attr, value of obj
      if _.isFunction(value) or attr == '_id' or attr == '_dirty' or attr == '_propertyCreated' or attr == '_klass'
        continue
      if _.isArray(value)
        _getMongoSet(prefix + '.' + attr, value, ret, obj, obj._dirty) #
      #else if value instanceof Base or value instanceof InLine
      else if value isnt undefined and (value._klass == 'Base' or value._klass == 'InLine')
        if value._klass == 'InLine'
          ret.push { object: baseParent, paths: [] }
          _getMongoSet(prefix + '.' + attr, value, ret, baseParent, baseDirty)
        else
          ret.push { object: obj, paths: [{path: prefix + '.' + attr, value: value}] }
      else if '_'+attr in obj._dirty #
        for dct in ret
          #if obj instanceof InLine
          if obj._klass == 'InLine'
            comp = baseParent
            baseDirty.push(prefix + '.' + attr)
          else
            comp = obj
          if _.isEqual(dct.object, comp)
            dct.paths.push {path: prefix + '.' +attr, value: obj[attr]} # comp
            break
  #delete obj._dirty

getMongoSet = (obj, dirty) ->
  out = [{object: obj, paths: []}]
  _getMongoSet('', obj, out, obj, dirty)
  return out


soop = {}
soop.Base  = Base
#soop.properties = properties
soop.InLine = InLine
soop.validate = validate
#soop.getMongoSet = getMongoSet
soop.array = array