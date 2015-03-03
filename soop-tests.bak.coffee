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

  it.skip 'test empty', (test) ->
    p1 = new Person {}
    try
      p1.save()
      test.equal 0,1
    catch
      test.equal 1,1

  it.skip 'test optional=true', (test) ->
    p1 = new Person {lastName: 'Alarcos'}
    try
      p1.save()
      test.equal 0,1
    catch
      test.equal 1,1

  it.skip 'test simplest fail', (test) ->
    p1 = new Person {firstName: 'Miguel'}
    try
      p1.save()
      test.equal 0,1
    catch
      test.equal 1,1

  it.skip 'test complex fail', (test) ->
    console.log '--------------------------------------------'
    p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}
    try
      c = new Complex
        r:50
        i:70

      p1.complex = c
      p1.save()
      test.equal 0,1
    catch error
      console.log error
      test.equal 1,1

  it.skip 'test mix', (test) ->
    console.log '--------------------------------------------'
    p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}
    try
      c = new Complex
        r:50
        i:70
        a: new A
          x: new Text
            text: 'hola mundo'
            ref: [[[new B x: 'game over!']]]
      p1.complex = c
      p1.save()
      test.equal 1,1
    catch
      test.equal 0,1

  it.skip 'test mix and findOne', (test) ->
    try
      console.log '************************************'
      p1 = new Person {firstName: 'Miguel'}
      c = new Complex
        r:50
        i:70
        a: new A
          x: new Text
            text: 'hola mundo'
            ref: [[[new B x: 'game over!']]]
      p1.complex = c
      console.log p1
      p1.save()
      console.log '-------------findOne'
      p2 = Person.findOne(p1._id)
      console.log p1, p2
      test.equal p1, p2
    catch error
      console.log error
      test.equal 1, 0

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
      console.log p
      #console.log 'CLONE'
      #p2 = p.clone()
      #console.log p2
      console.log '************ SAVE *********************************'
      p.save()
      console.log 'person', p
      #p2 = Person.findOne({_id: p._id})
      #console.log 'person2', p2

      #console.log 'iguales?', _.isEqual(p, p2)
      #test.equal p, p2

      #test.equal 1, 0