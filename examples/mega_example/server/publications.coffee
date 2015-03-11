Meteor.publishComposite 'dataComposite',
  find: ->
    return a.find({})
  children: soop.pCChildren(A)

