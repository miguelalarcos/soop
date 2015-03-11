exclude = ['_id', '_dirty', '_klass', '_propertyCreated', '_super__', 'constructor']

array = (v) ->
  v.set = setterArray(v)
  return v

nextSchemaAttr = (S, attr) ->
  x = S[attr].type
  while x[0]
    x = x[0]
  x.schema

nextKlassAttr = (K, attr) ->
  x = K.schema[attr].type
  while x[0]
    x = x[0]
  return x

getKlass = (obj) ->
  obj.constructor

isSubClass = (klass, super_) ->
  klass.prototype instanceof super_

elementValidate = (k, x, klass, optional)->
  if x is undefined and optional == true
    return {k:k, v: true, m: ''} #[true, '']
  if x is undefined
    return {k:k, v: false, m:'value undefined'} #[false, 'value undefined']
  if klass is String
    if _.isString(x)
      {k:k, v:true, m:''}
    else
      {k:k, v:false, m: x + ' must be String'}
  else if klass is Number
    if _.isNumber(x)
      {k:k, v:true, m:''}
    else
      {k:k, v:false. x + ' must be Number'}
  else if klass is Boolean
    if _.isBoolean(x)
      {k:k, v:true, m:''}
    else
      {k:k, v:false,  m: x + ' must be a Boolean'}
  else if klass is Date
    if _.isDate(x)
      {k:k, v:true, m:''}
    else
      {k:k, v:false,  m: x + ' must be a Date'}
  else
    if x instanceof klass
      {k:k, v:true, m:''}
    else
      {k:k, v:false,  m: x + ' must be of type ' + klass}

validateArray = (value, schema)->
  ret = []
  for v, i in value
    if _.isArray(v) #
      ret.push validateArray(v, schema[0]) #
    else if v instanceof Base or v instanceof InLine
      ret.push elementValidate(i, v, schema[0], schema.optional)
      ret.push validate(v) #, schema[0])
    else
      ret.push elementValidate(i, v, schema[0], schema.optional)
  return ret

validate = (obj) ->
  schema = getKlass(obj).schema
  ret = []
  obj2 = {}
  for key in _.keys(schema)
    keys_obj_without_ = (w[1..] for w in _.keys(obj))
    if key not in keys_obj_without_
      obj2[key] = undefined
    else
      obj2[key] = obj[key]
  for key, value of obj2
    if _.isFunction(value) or key in exclude
      continue
    if value instanceof Base or value instanceof InLine
      r = validate(value) #, schema[key].type.schema)
      ret = _.flatten(ret.concat(r))
    else if _.isArray(value)
      validateArray(value, schema[key].type)
    else
      ret.push elementValidate(key, value, schema[key].type, schema[key].optional)
  return ret

save_array = (array, schema)->
  ret = []
  toBDD = []
  toBDD._dirty = array._dirty
  for v in array
    if _.isArray(v)
      [docs, docs2] = save_array(v, schema[0])
      ret.push docs
      toBDD.push docs2
    else if _.isObject(v) and not (v instanceof Base)
      [doc, doc2 ]= save(v, schema[0].schema)
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


cloneWithFilter = (obj, filter) ->
  filter(obj)
  if _.isArray(obj)
    ret = []
    for v in obj
      ret.push cloneWithFilter(v, filter)
  else if _.isObject(obj)
    ret = {}
    for k,v of obj
      if _.isFunction(v)
        continue
      ret[k] = filter(cloneWithFilter(v, filter))
  else
    return obj
  return ret


filter = (obj) ->
  if not _.isObject(obj)
    return obj

  for attr, value of obj
    if _.isFunction(value) or attr in exclude
      delete obj[attr]
      continue

    if /^_/.test(attr) and attr not in exclude
      obj[attr[1..]] = obj[attr]
      delete obj[attr]
  return obj

save = (obj, schema)->
  ret = {}
  toBDD = {}

  for key, value of obj
    if not _.isFunction(value) and key not in exclude and /^_/.test(key)
      key = key[1..]
      if _.isArray(value)
        [ret[key], toBDD[key]] = save_array(value, schema[key].type)
      else if value instanceof Base
        [doc, nothing] = save(value, nextSchemaAttr(schema, key))
        toBDD[key] = doc._id
        ret[key] = doc
      else if value instanceof InLine
        [doc, doc2] = save(value, nextSchemaAttr(schema, key))
        ret[key] = doc
        toBDD[key] = doc2
      else
        ret[key] = value
        toBDD[key] = value

  toBDD._dirty = obj._dirty
  toBDD.constructor = getKlass(obj) # obj.constructor # refactorizar a toBDD._collection
  if obj instanceof Base
    toBDD._klass = 'Base'
  else if obj instanceof InLine
    toBDD._klass = 'InLine'
  if obj._id
    toBDD._id = obj._id

  if obj instanceof Base
    dirty = (x[1..] for x in obj._dirty)
    if obj._id is undefined
      for attr in exclude
        delete toBDD[attr]
      docToInsert = cloneWithFilter(toBDD, filter)
      obj._id = getKlass(obj).collection.insert(docToInsert)
      obj._dirty = []
    else
      for [elem, set, unset] in getMongoSet(toBDD, dirty)
        set = cloneWithFilter(set, filter)
        unset = cloneWithFilter(unset, filter)
        klass = getKlass(elem.object)
        if klass.collection and (not _.isEmpty(set) or not _.isEmpty(unset))
          klass.collection.update(elem.object._id, {$set: set, $unset: unset})
          #elem.object._dirty = []
          obj._dirty = []
    #
    ret._id = obj._id
  return [ret, toBDD]

createArray = (value, schema)-> # no se le pasa un schema sino un schema_key
  ret = []
  for v in value
    if _.isArray(v)
      ret.push createArray(v, schema[0] or schema.type[0])
    else
      klass = schema[0] or schema.type[0]
      if _.isString(v) and isSubClass(klass, Base)
        ret.push new klass({_id: v})
      else if isSubClass(klass, Base)
        if v instanceof Base
          ret.push v
          create v, getKlass(v).schema
        else
          ret.push new klass(v)
      else if isSubClass(klass, InLine)
        if v instanceof InLine
          ret.push v
          create v, getKlass(v).schema
        else
          ret.push new klass(v)
      else
        ret.push v
  return ret

create = (obj, schema)->

  ret = {}
  for key, value of obj
    if _.isFunction(value) or key in exclude
      continue
    if /^_/.test(key)
      key_ = key[1..]
    else
      key_ = key
    if key_ not in _.keys(schema)
      continue
    if _.isArray(value)
      ret['_'+key_] = createArray(value, schema[key_])
    else if _.isObject(value) and not (value instanceof Base) and not (value instanceof InLine)
      ret['_'+key_] = new schema[key_].type(value, false)
    else if _.isString(value) and schema[key_] and isSubClass(schema[key_].type, Base)
      ret['_'+key_] = new (schema[key_].type)({_id: value})
    else
      ret['_'+key_] = value
  return ret

class Base
  constructor: (args, doFindOne)->
    if doFindOne is undefined then doFindOne = true
    args = args or {}
    if _.isString(args) then args = {_id: args}

    klass = getKlass(@)
    if args._id
      @_id = args._id
      if doFindOne
        args = klass.collection.findOne(args._id)

    schema = klass.schema
    values = create args, schema

    for key, value of values
      if not _.isFunction(value)
        @[key] = value

    #if not @_propertyCreated
    properties(@)
    #  @_propertyCreated = true

    @_dirty = []
    @_klass = 'Base'

  isValid : ->
    _.all( (x.v for x in validate(@, getKlass(@).schema ) ))

  save: ->
    save(@, @constructor.schema)

  @findOne: (_id) ->
    new @({_id: _id})

class InLine
  constructor: (args)->

    schema = getKlass(@).schema
    for key, value of args
      if /^_/.test(key) then key = key[1..]
      if (key in exclude) or (key not in _.keys(schema))
        continue
      klass = schema[key].type
      if _.isArray(value)
        @['_'+key] = createArray value, klass
      else if isSubClass(klass, InLine) or isSubClass(klass, Base)
        @['_'+key] = new klass value
      else
        @['_'+key] = value

    #if not @_propertyCreated
    properties(@)
    #  @_propertyCreated = true
    @_klass = 'InLine'
    @_dirty = []

  isValid : ->
    _.all( (x.v for x in validate(@, getKlass(@).schema ) ))

getter_setter = (obj, attr) ->
  get: -> obj[attr]
  set: (value) ->
    obj[attr] = value
    if attr not in obj._dirty
      obj._dirty.push attr

setterArray = (array) ->
  array._dirty = []
  (index, value) ->
    array[index] = value
    if index not in array._dirty
      array._dirty.push index

properties = (obj) ->
  if obj is undefined
    return
  for attr, value of getKlass(obj).schema #obj.constructor.schema
    if _.isArray(value.type) and obj['_' + attr] isnt undefined
      Object.defineProperty obj, attr, getter_setter(obj, '_' + attr)
      obj[attr].set = setterArray(obj['_' + attr])
    else if ( isSubClass(value.type, Base) or isSubClass(value.type, InLine)) and obj['_' + attr] isnt undefined
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
          if i in obj._dirty
            out.push {path: prefix + '.' + i, value: v}
          ret.push { object: v, paths: [] }
          _getMongoSet(prefix + '.' + i, v, ret, baseParent, baseDirty)
        else
          if i in obj._dirty
            out.push {path: prefix + '.' + i, value: v}
            baseDirty.push(prefix + '.' + i)
  else
    if obj is undefined
      return
    for attr, value of obj
      if _.isFunction(value) or attr in exclude
        continue
      if _.isArray(value)
        if '_'+attr in obj._dirty
          ret.push { object: obj, paths: [{path: prefix + '.' + attr, value: value}] }
        else
          _getMongoSet(prefix + '.' + attr, value, ret, obj, obj._dirty) #
      else if '_'+attr in obj._dirty
        for dct in ret
          if obj._klass == 'InLine'
            comp = baseParent
            baseDirty.push(prefix + '.' + attr)
          else
            comp = obj
          if _.isEqual(dct.object, comp)
            dct.paths.push {path: prefix + '.' +attr, value: obj[attr]}
            break
      if value isnt undefined and (value._klass == 'Base' or value._klass == 'InLine')
        if value._klass == 'InLine'
          ret.push { object: baseParent, paths: [] }
          _getMongoSet(prefix + '.' + attr, value, ret, baseParent, baseDirty)
        else
          ret.push { object: obj, paths: [{path: prefix + '.' + attr, value: value}] }
    delete obj._dirty
    delete obj._klass

getMongoSet = (obj, dirty) ->
  out = [{object: obj, paths: []}]
  _getMongoSet('', obj, out, obj, dirty)
  ret = []
  for elem in out
    set = {}
    unset = {}
    for pv in elem.paths
      if pv.value is undefined
        unset[pv.path[1..]] = ''
      else if pv.path not in exclude
        set[pv.path[1..]] = pv.value
    ret.push [elem, set, unset]
  return ret

traverseSubDocs = (root, path) ->
  if /^\./.test(path) then path = path[1..]
  console.log path, root
  currentSubDoc = root
  subdocs = []
  paths = path.split('.')
  while paths.length > 0
    index = paths.shift()
    if index == '$'
      for elem, i in currentSubDoc
        subdocs.push traverseSubDocs(currentSubDoc[i], paths.join('.'))
    else
      currentSubDoc = currentSubDoc[index]

  if currentSubDoc isnt undefined
    subdocs.push currentSubDoc
  console.log _.flatten(subdocs)
  return _.flatten(subdocs)

children = (K, baseCollection, path, baseKlass) ->
  lista = []
  for key, value of K.schema
    if key in exclude or _.isFunction(value)
      continue
    if _.isArray(value.type)
      klass = value.type[0]
      while klass[0]
        klass = klass[0]
      if isSubClass(klass, Base)
        collection = klass.collection
        path_ = path + '.$.' + key
        if /^\./.test(path_) then path_ = path_[1..]
        if /^\$\./.test(path_) then path_ = path_[2..]
        docs = [{
          find: (x) ->
            rootDoc = x
            collection.find({_id: {$in: traverseSubDocs(rootDoc, path_) }})
          children: children(klass, collection, '', klass)
        }]
        docs[0].collection = collection
        docs[0].path = path_
        docs[0].klass = klass
        return docs # seguro que hay que hacer return y no un lista.push ??? !!!!!!!!!!!!!!!!!!!!!!!!!!!! ALERT
        #lista.push docs
      else if isSubClass(klass, InLine)
        lista.push children(klass, baseCollection, path+'.'+key, baseKlass)
    else
      klass = value.type
      if isSubClass(klass, Base)
        #lista.push children(klass, klass.collection, path+'.'+key, klass)
        docs = [
          find: (x) ->
            rootDoc = x
            klass.collection.find({_id: {$in: traverseSubDocs(rootDoc, path+'.'+key) }})
          children: children(klass, klass.collection, '', klass)
        ]
        lista.push docs
      else if isSubClass(klass, InLine)
        lista.push children(klass, baseCollection, path+'.'+key, baseKlass)
  return _.flatten(lista)

pCChildren = (K) ->
  return children(K, K.collection, '', K)

soop = {}
soop.Base  = Base
soop.InLine = InLine
soop.validate = validate
soop.array = array
soop.pCChildren = pCChildren
soop._nextSchemaAttr = nextSchemaAttr
soop._traverseSubDocs = traverseSubDocs
soop._children = children
soop._nextKlassAttr = nextKlassAttr