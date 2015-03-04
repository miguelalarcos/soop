a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'


Meteor.methods
  'delete': ->
    a.remove({})
    c.remove({})

a.allow
  insert: -> true
  update: -> true
c.allow
  insert: -> true
  update: -> true
