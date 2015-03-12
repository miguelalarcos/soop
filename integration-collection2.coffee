a = new Mongo.Collection 'TestA2'
c = new Mongo.Collection 'TestC2'

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: String
    c2:
      type: [Number]
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
      test.equal 1, 1

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
      test.equal 1, 1


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