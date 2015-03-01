person = new Mongo.Collection('TestPerson')

Meteor.methods
  'delete': ->
    person.remove({})

person.allow
  insert: -> true