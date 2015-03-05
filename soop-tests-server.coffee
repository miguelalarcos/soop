a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'
x = new Mongo.Collection 'TestX'
y = new Mongo.Collection 'TestY'

Meteor.methods
  'delete': ->
    a.remove({})
    c.remove({})
    x.remove({})
    y.remove({})

a.allow
  insert: -> true
  update: -> true
c.allow
  insert: -> true
  update: -> true
x.allow
  insert: -> true
  update: -> true
y.allow
  insert: -> true
  update: -> true