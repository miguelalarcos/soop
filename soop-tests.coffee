person = new Mongo.Collection 'TestPerson'
a = new Mongo.Collection 'TestA'
b = new Mongo.Collection 'TestB'

class B extends soop.Base
  @collection: b
  @schema:
    x:
      type: String

class Text extends soop.inLine
  @schema:
    text:
      type: String
    ref:
      type: B

class A extends soop.Base
  @collection: a
  @schema:
    x:
      type: Text

class Complex extends soop.inLine
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
    Meteor.call 'delete'

  it 'test simplest', (test) ->
    p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}
    try
      p1.save()
      test.equal 0,1
    catch
      test.equal 1,1


  it 'test adding an attribute inline', (test) ->
    p1 = new Person {firstName: 'Miguel'}
    p1.complex = new Complex
      r:50
      i:70
      a: new A
        x: new Text
          text: 'hola mundo'
          ref: new B
            x: 'game over!'

    p1.save()
    p2 = Person.findOne(p1._id)
    console.log p1
     #_.isEqual(p1,p2)
    test.equal p1, p2