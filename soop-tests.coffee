a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'

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

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: String
    a2:
      type: C
    a3:
      type: B

describe 'suite basics', ->
  beforeEach (test)->
    Meteor.call 'delete'

  afterEach (test) ->
    #Meteor.call 'delete'

  it 'test new A', (test)->
    a1 = new A
      a: 'hello world'

    test.equal a1.a, 'hello world'
    test.isFalse _.all(soop.validate(a1, A.schema))

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
        b3: [new C c:'atari']

    test.equal a1.a3.b3[0].c, 'atari'

  it 'test save A', (test)->
    a1 = new A
      a: 'hello world'

    a1.save()
    #test.isNotNull(a1._id)
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
    doc = a.findOne()
    test.isTrue _.isString(doc.a3.b3[0])

  it 'test validate A+C+B+C+[C]', (test)->
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

    test.isTrue _.all(soop.validate(a1, A.schema))