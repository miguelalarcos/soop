a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'
x = new Mongo.Collection 'TestX'
y = new Mongo.Collection 'TestY'
x_collection = x

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: String

class B extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: C
    b3:
      type: [C]
    b4:
      type: [Number]
    b5:
      type: [[C]]

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: String
    a2:
      type: C
      optional: false
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

  it 'test new A + validate false', (test)->
    a1 = new A
      a: 'hello world'

    test.equal a1.a, 'hello world'
    #test.isFalse soop.isValid(a1)
    test.isFalse a1.isValid()
    #test.isFalse _.all((x.v for x in soop.validate(a1, A.schema)))

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
        b3: soop.array([new C c:'atari'])

    test.equal a1.a3.b3[0].c, 'atari'


  it 'test save A', (test)->
    a1 = new A
      a: 'hello world'

    a1.save()
    test.notEqual undefined, a1._id

  it 'test save A+C', (test)->
    a1 = new A
      a: 'hello world'
      a2: new C
        c: 'insert coin'

    a1.save()
    #test.isNotNull(a1.a2._id)
    test.notEqual undefined, a1.a2._id

  it 'test save A+B+C', (test)->
    a1 = new A
      a: 'hello world'
      a3: new B
        b: 'insert coin'
        b2: new C
          c: 'amstrad'

    a1.save()
    #test.isNotNull(a1.a3.b2._id)
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

  it 'test validate true A+C+B+C+[C]', (test)->
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

    #test.isTrue soop.isValid(a1)
    test.isTrue a1.isValid()
    #test.isTrue _.all( (x.v for x in soop.validate(a1, A.schema ) ))

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

    #soop.properties(a1)
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

    #soop.properties(x)
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

    #soop.properties(x)
    x.save()
    x.x.y2[0].z = 'world'
    x.save()

    x2 = X.findOne(x._id)
    test.equal x2.x.y2[0].z, 'world'

  it 'test XY[number]', (test)->
    x = new X
      x: new Y
        y3: [1]

    #soop.properties(x)
    x.save()
    x.x.y3.set(0,  3)
    x.save()

    x2 = X.findOne(x._id)
    test.equal x2.x.y3[0], 3

  it 'test XYy3[number]', (test)->
    x = new X
      x: new Y
        y3: [1]

    #soop.properties(x)
    x.save()
    x.x.y3 = soop.array([1,3])
    x.x.y3.set(1, 5)
    x.save()
    x2 = X.findOne(x._id)
    test.equal x2.x.y3, [1,5]

  it 'test XYy3[number]b', (test)->
    x = new X
      x: new Y
        y3: [1]

    #soop.properties(x)
    x.save()
    x.x = new Y
      y3: [2,5]
    x.save()
    x2 = X.findOne(x._id)
    test.equal x2.x.y3, [2,5]

  it 'test XYy3[number]undfined', (test)->
    x = new X
      x: new Y
        y3: [1]

    #soop.properties(x)
    x.save()
    x.x = undefined
    x.save()
    x2 = X.findOne(x._id)
    test.equal x2.x, undefined
    #x3 = x_collection.findOne(x._id)
    #test.equal x3.x, undefined