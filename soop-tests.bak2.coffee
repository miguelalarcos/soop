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
    #console.log p
    p.save()
    console.log '------------ FINDONE -------------'
    p2 = Person.findOne({_id:p._id})
    #console.log p2
    #test.equal p, p2
