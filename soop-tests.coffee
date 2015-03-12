a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'
x = new Mongo.Collection 'TestX'
y = new Mongo.Collection 'TestY'
u = new Mongo.Collection 'TestU'
w = new Mongo.Collection 'TestW'
x_collection = x
a_collection = a
c_collection = c
y_collection = y

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
    b3:
      type: [C]
      optional: true
    b4:
      type: [Number]
      optional: true
    b5:
      type: [[C]]
      optional: true

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: String
    a2:
      type: C
      optional: true
    a3:
      type: B

class Z extends soop.InLine
  @schema:
    z:
      type: String

class Y extends soop.Base
  @collection: y
  @schema:
    y:
      type: Z
    y2:
      type: [Z]
    y3:
      type: [Number]

class X extends soop.Base
  @collection: x
  @schema:
    x:
      type: Y

describe 'suite basics', ->
  beforeEach (test)->
    Meteor.call 'delete'

  afterEach (test) ->
    Meteor.call 'delete'

  it.skip 'test new A + validate false', (test)->
    a1 = new A
      a: 'hello world'

    test.equal a1.a, 'hello world'
    test.isFalse a1.isValid()
    test.isFalse _.all((x.v for x in soop.validate(a1))) #, A.schema)))

  it.skip 'test new A + optional -> validate true', (test)->
    a1 = new A
      a: 'hello world'
      a3: new B
        b: 'please validate'

    test.equal a1.a, 'hello world'
    test.isTrue a1.isValid()
    test.isTrue _.all((x.v for x in soop.validate(a1)))

  it 'test new A+C', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'

    test.equal a1.a2.c, 'insert coin'

  it 'test new A+C+B+C', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'

    test.equal a1.a3.b2.c, 'amstrad'


  it 'test new A+C+B', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'

    test.equal a1.a3.b, 'game over!'

  it 'test new A+C+B+C+[C]', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        #b3: soop.array([new C c:'atari'])
        b3: [new C c:'atari']

    test.equal a1.a3.b3[0].c, 'atari'


  it 'test save A', (test)->
    a1 = new A
      a: 'hello world'

    a1.save()
    test.notEqual undefined, a1._id

  it 'test save C', (test)->
    c1 = new C
      c2: [1,2,3,4,5]

    c1.save()
    #c1.c2[1] = 0
    c1.c2.set(1, 0)
    c1.save()
    c2 = C.findOne(c1._id)
    test.equal c1, c2

  it 'test save A+C', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'

    a1.save()
    test.isNotNull(a1.a2._id)
    test.notEqual undefined, a1.a2._id

  it 'test save A+B+C', (test)->
    a1 = new A
      a: 'hello world'
      a3: new B
        b: 'insert coin'
        b2: new C
          c: 'amstrad'

    a1.save()
    test.isNotNull(a1.a3.b2._id)
    test.notEqual undefined, a1.a3.b2._id

  it 'test save+findOne A', (test)->
    a1 = new A
      a: 'hello world'

    a1.save()
    a2 = A.findOne(a1._id)
    test.equal a1, a2

  it 'test save+findOne A+C', (test)->

    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'

    a1.save()
    a2 = A.findOne(a1._id)
    test.equal a1, a2


  it 'test save+findOne A+C+B+C+[C]', (test)->

    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        b3: [new C c:'atari']
        b4: [1,2,3,4,5]

    a1.save()
    a2 = A.findOne(a1._id)
    test.equal a1, a2

    #doc = a.findOne(a1._id) #
    #test.isTrue _.isString(doc.a3.b3[0])  # fail in the server travis; test again
    #test.isTrue _.isString(doc.a2)
    #test.isTrue _.isString(doc.a3.b2)

  it.skip 'test validate true A+C+B+C+[C]', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        b3: [new C c:'atari']
        b4: [1,2,3,4,5]
        b5: [[new C c:'atari']]

    test.isTrue a1.isValid()
    test.isTrue _.all( (x.v for x in soop.validate(a1))) #, A.schema ) ))

  it 'test types A+C+B+C+[C]', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        b3: [new C c:'atari']
        b4: [1,2,3,4,5]
    a1.save()

    a2 = A.findOne(a1._id)

    test.isTrue a2 instanceof A
    test.isTrue a2.a2 instanceof C
    test.isTrue a2.a3 instanceof B
    test.isTrue a2.a3.b2 instanceof C
    test.isTrue a2.a3.b3[0] instanceof C


  it 'test save+findOne A+C+B+C+[[C]]', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        b5: [[new C c:'atari']]

    a1.save()
    a2 = A.findOne(a1._id)
    test.equal a1, a2

    #doc = a.findOne(a1._id) #
    #test.isTrue _.isString(doc.a3.b5[0][0])  # fail in the server travis; test again

  it 'test properties', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b3: [new C c:'atari']

    a1.save()
    a1.a = 7
    a1.a2.c = 'mundo'
    a1.a3.b = 'hola'
    a1.a3.b3[0].c = 'nintendo'

    a1.save()

    a2 = A.findOne(a1._id)

    test.equal a2.a, 7
    test.equal a2.a2.c, 'mundo'
    test.equal a2.a3.b, 'hola'
    test.equal a2.a3.b3[0].c, 'nintendo'



  it 'test XYZ', (test)->
    x = new X
      x: new Y
        y: new Z
          z: 'hello'

    x.save()
    x.x.y.z = 'world'
    x.save()

    x2 = X.findOne(x._id)
    test.equal x2.x.y.z, 'world'


  it 'test XY[Z]', (test)->
    x = new X
      x: new Y
        y2: [new Z
          z: 'hello']

    x.save()
    x.x.y2[0].z = 'world'

    x.save()

    x2 = X.findOne(x._id)
    test.equal x2.x.y2[0].z, 'world'

  it 'test XY[number]', (test)->
    x = new X
      x: new Y
        y3: [1]

    x.save()

    x.x.y3.set(0,  3)
    #x.x.y3[0]=3
    x.save()

    x2 = X.findOne(x._id)
    test.equal x2.x.y3[0], 3

  it 'test XYy3[number]', (test)->
    x = new X
      x: new Y
        y3: [1]

    x.save()
    x.x.y3 = soop.array([1,3])
    x.x.y3.set(1, 5)

    #x.x.y3 = [1,3]
    #x.x.y3[1]=5

    x.save()
    x2 = X.findOne(x._id)
    test.equal x2.x.y3, [1,5]

  it 'test XYy3[number]b', (test)->
    x = new X
      x: new Y
        y3: [1]

    x.save()
    x.x = new Y
      y3: [2,5]

    x.save()
    x2 = X.findOne(x._id)
    test.equal x2.x.y3, [2,5]


  it 'test XYy3[number]undefined', (test)->
    x = new X
      x: new Y
        y3: [1]

    x.save()
    x.x = undefined
    x.save()
    x2 = X.findOne(x._id)
    test.equal x2.x, undefined
    x3 = x_collection.findOne(x._id)
    test.equal x3.x, undefined

describe 'suite insert', ->
  beforeEach (test)->
    Meteor.call 'delete'
    spies.create('insert_A', a_collection, 'insert')
    spies.create('insert_C', c_collection, 'insert')

  afterEach (test) ->
    Meteor.call 'delete'
    spies.restore('insert_A')
    spies.restore('insert_C')

  it 'test insert call basic', (test)->
    a1 = new A
      a: 'hello world'

    a1.save()
    expect(spies.insert_A).to.have.been.calledWith({a: "hello world"})

  it 'test insert A+C', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'

    a1.save()
    expect(spies.insert_C).to.have.been.calledWith({c: "insert coin"})
    expect(spies.insert_A).to.have.been.calledWith({a: "hello world", a2: a1.a2._id})

  it 'test insert A+C+B+C', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'

    a1.save()

    expect(spies.insert_C).to.have.been.calledWith({c: "amstrad"})
    expect(spies.insert_C).to.have.been.calledWith({c: "insert coin"})
    expect(spies.insert_A).to.have.been.calledWith({a: "hello world", a2: a1.a2._id, a3: {b: "game over!", b2: a1.a3.b2._id}})


  it 'test insert A+C+B', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'

    a1.save()
    expect(spies.insert_C).to.have.been.calledWith({c: "insert coin"})
    expect(spies.insert_A).to.have.been.calledWith({a: "hello world", a2: a1.a2._id, a3: {b: "game over!"}})


  it 'test insert A+C+B+C+[C]', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        #b3: soop.array([new C c:'atari'])
        b3 : [new C c:'atari']

    a1.save()
    expect(spies.insert_C).to.have.been.calledWith({c: "insert coin"})
    expect(spies.insert_C).to.have.been.calledWith({c: "amstrad"})
    expect(spies.insert_A).to.have.been.calledWith({a: "hello world", a2: a1.a2._id, a3: {b: "game over!", b2: a1.a3.b2._id, b3: [ a1.a3.b3[0]._id ]}})

  it 'test save+findOne A+C+B+C+[[C]]', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'
        b5: [[new C c:'atari']]

    a1.save()
    doc =
      a : "hello world"
      a2: a1.a2._id
      a3:
        b: "game over!"
        b2: a1.a3.b2._id
        b5: [[ a1.a3.b5[0][0]._id ]]
    expect(spies.insert_A).to.have.been.calledWith(doc)

describe 'suite update', ->
  beforeEach (test)->
    Meteor.call 'delete'
    spies.create('update_A', a_collection, 'update')
    spies.create('update_C', c_collection, 'update')
    spies.create('insert_C', c_collection, 'insert')
    spies.create('update_Y', y_collection, 'update')

  afterEach (test) ->
    Meteor.call 'delete'
    spies.restore('update_A')
    spies.restore('update_C')
    spies.restore('insert_C')
    spies.restore('update_Y')

  it 'test update call basic', (test)->
    a1 = new A
      a: 'hello world'

    a1.save()
    a1.a = 'game over!'
    a1.save()
    expect(spies.update_A).to.have.been.calledWith(a1._id, {$set:{a: 'game over!'}, $unset: {}})

  it 'test update call ', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'

    a1.save()

    a1.a2.c = undefined
    a1.a3 = new B
      b: 'atari'

    a1.save()

    #falta el test

  it 'test update call overwrite', (test)->
    a1 = new A
      a: 'hello world'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'

    a1.save()

    a1.a3.b2.c = 'atari'
    a1.a3 = new B
      b2: new C
        c: 'sega'

    a1.a3.b2.c = 'nintendo'
    a1.save()

    expect(spies.update_A).to.have.been.calledWith(a1._id, {$set:{a3: {b2: a1.a3.b2._id}}, $unset: {}})
    expect(spies.insert_C).to.have.been.calledWith({c: 'nintendo'})


  it 'test update call 2', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'

    a1.save()
    a1.a3.b2.c = 'atari'
    a1.save()
    expect(spies.update_C).to.have.been.calledWith(a1.a3.b2._id, {$set:{c:'atari'}, $unset: {}})

  it 'test update call 3', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'
      a3: new B
        b: 'game over!'
        b2: new C
          c: 'amstrad'

    a1.save()
    a1.a3.b2 = new C
      c: 'atari'
    a1.save()
    expect(spies.update_A).to.have.been.calledWith(a1._id, {$set:{'a3.b2': a1.a3.b2._id}, $unset: {}})


  it 'test update consecutive calls', (test)->
    c1 = new C
      c: 'hello world'
      c2: [1,2,3]

    c1.save()
    c1.c = 'game over!'
    c1.save()
    c1.c2 = soop.array([4,5])
    c1.save()

    expect(spies.update_C).to.have.been.calledWith(c1._id, {$set: {c2: [4,5]}, $unset: {}})

  it 'test update consecutive calls 2', (test)->
    y = new Y
      y2: [new Z(z: 'nintendo'), new Z(z: 'atari')]
      y3: [1,2,3]

    y.save()
    y.y3 = soop.array([4,5])
    y.save()
    y.y2 = soop.array([new Z(z: 'sega'), new Z(z: 'sony')])
    y.save()

    expect(spies.update_Y).to.have.been.calledWith(y._id, {$set: {y2: [{z: 'sega'}, {z: 'sony'}]}, $unset: {}})

  it 'test update dirty index array', (test)->
    c1 = new C
      c: 'hello world'
      c2: [1,2,3]

    c1.save()
    c1.c2.set(1, 5)
    c1.save()

    expect(spies.update_C).to.have.been.calledWith(c1._id, {$set: {'c2.1': 5}, $unset: {}})

  it 'test update dirty index array Z', (test)->
    y = new Y
      y2: [new Z(z: 'nintendo'), new Z(z: 'atari')]
      y3: [1,2,3]

    y.save()
    y.y2.set(0, new Z(z: 'sega'))
    y.save()

    expect(spies.update_Y).to.have.been.calledWith(y._id, {$set: {'y2.0': {z: 'sega'}}, $unset: {}})

