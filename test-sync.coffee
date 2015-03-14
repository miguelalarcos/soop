a = new Mongo.Collection "TestA4"
c = new Mongo.Collection "TestC4"

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: Number

class B extends soop.InLine
  @schema:
    b:
      type: Number
    b2:
      type: C
    b3:
      type: [C]

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: Number
    a2:
      type: B
    a3:
      type: [Number]
    a4:
      type: [B]

describe 'suite test sync', ->
  beforeEach (test)->
    a.remove({})
    c.remove({})

  afterEach (test) ->
    a.remove({})
    c.remove({})

  it 'test basic sync', (test) ->
    elem = new A(a:7)
    elem.save()
    a.update({_id: elem._id}, {$set: {a:8}})
    elem.sync()
    test.equal elem.a, 8

  it 'test basic sync due to a findOne', (test) ->
    elem = new A(a:7)
    elem.save()
    a.update({_id: elem._id}, {$set: {a:8}})
    elem = A.findOne(elem._id)
    test.equal elem.a, 8

  it 'test sync A->B', (test) ->
    elem = new A
      a: 7
      a2: new B(b:100)
    elem.save()
    a.update({_id: elem._id}, {$set: {'a2.b': -1}})
    elem.sync()
    test.equal elem.a2.b, -1

  it 'test basic array sync', (test) ->
    elem = new A(a3: [7, 8])
    elem.save()
    a.update({_id: elem._id}, {$set: {a3: [80,90]}})
    elem.sync()
    test.equal elem.a3, [80, 90]

  it 'test A->[B] sync', (test) ->
    elem = new A(a4: [new B(b:8), new B(b:9)])
    elem.save()
    a.update({_id: elem._id}, {$set: {a4: [new B(b:80), new B(b:90)]}})
    elem.sync()
    test.equal elem.a4[0].b, 80

  it 'test sync A->B->C', (test) ->
    c_elem = new C(c: 5)
    elem = new A
      a2: new B
        b2: c_elem

    elem.save()
    c.update({_id: c_elem._id}, {$set: {c: -1}})
    elem.sync()
    test.equal elem.a2.b2.c, -1

  it 'test sync A->B->[C]', (test) ->
    c_elem = new C(c: 5)
    elem = new A
      a2: new B
        b3: [c_elem]

    elem.save()
    c.update({_id: c_elem._id}, {$set: {c: -1}})
    elem.sync()
    test.equal elem.a2.b3[0].c, -1

  it 'test sync A->[B]->C', (test) ->
    c_elem = new C(c: 5)
    elem = new A
      a4: [new B
        b2: c_elem
        ]

    elem.save()
    c.update({_id: c_elem._id}, {$set: {c: -1}})
    elem.sync()
    test.equal elem.a4[0].b2.c, -1

  it 'test sync A->[B]->[C]', (test) ->
    c_elem = new C(c: 5)
    elem = new A
      a4: [new B
             b3: [c_elem]
      ]

    elem.save()
    c.update({_id: c_elem._id}, {$set: {c: -1}})
    elem.sync()
    test.equal elem.a4[0].b3[0].c, -1

  it 'test sync A->B->(C)', (test) ->
    elem = new A
      a2: new B

    elem.save()

    a.update({_id: elem._id}, {$set: {'a2.b2': {c: -1}}})
    elem.sync()
    test.equal elem.a2.b2.c, -1


  it 'test sync A->[B]->(C)', (test) ->
    elem = new A
      a4: [new B]

    elem.save()

    a.update({_id: elem._id}, {$set: {'a4.0.b2': {c: -1}}})
    elem.sync()
    test.equal elem.a4[0].b2.c, -1

  it 'test sync A->B->new[C]', (test) ->
    elem = new A
      a2: new B

    elem.save()

    a.update({_id: elem._id}, {$set: {'a2.b3': [{c: -1}]}})
    elem.sync()
    test.equal elem.a2.b3[0].c, -1