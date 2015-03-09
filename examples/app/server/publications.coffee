Meteor.publishComposite 'dataComposite',
  find: ->
    return a.find({})
  children: soop.children(A.schema)