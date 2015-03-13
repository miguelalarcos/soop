a = new Mongo.Collection 'TestA3'
c = new Mongo.Collection 'TestC3'

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: Number

class B extends soop.InLine
  @schema:
    b:
      type: C

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: B

describe 'test space', ->
  beforeEach (test)->
    a.remove({})
    c.remove({})
    spies.create('findOne_a', a, 'findOne')
    spies.create('findOne_c', c, 'findOne')
    soop.Base.space = {}

  afterEach (test) ->
    a.remove({})
    c.remove({})
    spies.restore('findOne_a')
    spies.restore('findOne_c')
    soop.Base.space = {}

  it 'test simple space', (test) ->
    elem = new A
      a: new B
        b: new C
          c: 5

    elem.save()
    elem2 = A.findOne(elem._id)
    expect(spies.findOne_a).to.not.have.been.called

  it 'test nested space', (test) ->
    elem = new A
      a: new B
        b: new C
          c: 5

    elem.save()
    elem_c = C.findOne(elem.a.b._id)
    expect(spies.findOne_c).to.not.have.been.called
    _id = elem._id
    elem.remove()
    test.isFalse _id in soop.Base.space
    elem_c.remove()
    test.equal soop.Base.space, {}