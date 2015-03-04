###
person = new Mongo.Collection 'TestPerson'
a = new Mongo.Collection 'TestA'
b = new Mongo.Collection 'TestB'

class B extends soop.Base
  @collection: b
  @schema:
    x:
      type: String

class Text extends soop.InLine
  @schema:
    text:
      type: String
    ref:
      type: [[[B]]]

class A extends soop.Base
  @collection: a
  @schema:
    x:
      type: Text

class Complex extends soop.InLine
  @schema:
    r:
      type: Number
    i:
      type: Number
    a:
      type: A

class Person extends soop.Base
  @collection: person
  @schema :
    firstName:
      type: String
    lastName:
      type: String
      optional: true
    complex:
      type: Complex



describe 'suite basics', ->
  beforeEach (test)->
    Meteor.call 'delete'

  afterEach (test) ->
    #Meteor.call 'delete'

  it 'test', (test)->
    p = new Person {firstName: 'Miguel'}
    c = new Complex
      r:50
      i:70
      a: new A
        x: new Text
          text: 'insert coin'
          ref: [[[new B x: 'game over!']]]
    p.complex = c
    #console.log c
    #console.log p
    console.log '--------- SAVE --------------'
    p.save()
    console.log p
    console.log '--------- FINDONE --------------'
    p2 = Person.findOne(p._id)
    console.log p2
    test.equal p, p2

###

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
    console.log '**********************+'
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
    console.log '------------ FINDONE --------------'
    a2 = A.findOne(a1._id)
    console.log a1
    console.log a2
    test.equal a1, a2