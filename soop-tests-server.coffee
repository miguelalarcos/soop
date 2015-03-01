person = new Mongo.Collection('TestPerson')
a = new Mongo.Collection 'TestA'
b = new Mongo.Collection 'TestB'

Meteor.methods
  'delete': ->
    person.remove({})
    a.remove({})
    b.remove({})

person.allow
  insert: -> true
a.allow
  insert: -> true
b.allow
  insert: -> true
