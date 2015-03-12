a = new Mongo.Collection 'TestA2'
c = new Mongo.Collection 'TestC2'

class D extends soop.InLine
  @schema:
    d:
      type: Number

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: String
    c2:
      type: [Number]
      optional: true
    c3:
      type: [D]
      optional: true

class B extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: C
      optional: true

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: String
    a2:
      type: B
      optional: true

soop.attachSchema(A)

describe 'basic suite integration with aldeed:collection2', ->
  beforeEach (test)->
    a.remove({})
    c.remove({})

  afterEach (test) ->
    a.remove({})
    c.remove({})


  it 'test basic save that fails', (test) ->
    elem = new A
    try
      elem.save()
      test.equal 0,1
    catch error
      if error.sanitizedError
        test.equal 1, 1
      else
        console.log error
        test.equal 0, 1

  it 'test fails at last level', (test) ->
    elem = new A
      a: 'hello world'
      a2: new B
        b: 'insert coin'
        b2: new C
    try
      elem.save()
      test.equal 0,1
    catch error
      if error.sanitizedError
        test.equal 1, 1
      else
        console.log error
        test.equal 0, 1

  it 'test basic C ok', (test)->
    elem = new C
      c: 'credits'

    try
      elem.save()
      test.equal 0,0
      elem2 = C.findOne(elem._id)
      test.equal elem, elem2
    catch error
      console.log error
      test.equal 1, 0

  it 'test C ok', (test)->
    elem = new C
      c: 'credits'
      c2: [1,2,3]
    try
      elem.save()
      test.equal 0,0
      elem2 = C.findOne(elem._id)
      test.equal elem, elem2
    catch error
      console.log error
      test.equal 1, 0

  it 'test A->B->C', (test) ->
    elem = new A
      a: 'hello world'
      a2: new B
        b: 'insert coin'
        b2: new C
          c: 'game over!'
          c2: [5,6,7]

    try
      elem.save()
      test.equal 0,0
      elem2 = A.findOne(elem._id)
      test.equal elem, elem2
    catch error
      test.equal 1, 0

  it 'test validate', (test) ->
    elem = new A
      a: 'hello world'
      a2: new B
        b: 'insert coin'
        b2: new C
          c: 'game over!'
          c2: [5,6,7]

    test.isTrue elem.isValid()

  it 'test validate [D]', (test) ->
    elem = new A
      a: 'hello world'
      a2: new B
        b: 'insert coin'
        b2: new C
          c: 'game over!'
          c2: [5,6,7]
          c3: [new D(d:1), 2]

    test.isFalse elem.isValid()
    for x in soop.validate(elem)
      if x.valid is false
        test.equal x.path, '.a2.b2.c3.1.d'
        test.equal x.message, 'D is required'
        break