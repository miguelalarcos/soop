person = new Mongo.Collection 'TestPerson'

class Text extends soop.inLine
  @schema:
    text:
      type: String

class Complex extends soop.inLine
  @schema:
    r:
      type: Number
    i:
      type: Number
    t:
      type: Text

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
    p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}

    p1.complex = new Complex
      r:50
      i:70
      t:
        new Text
          text: 'hola mundo'

    p1.save()
    p2 = Person.findOne(p1._id)
    test.equal p1, p2