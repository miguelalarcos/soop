#Meteor.publishComposite 'dataComposite',
#  find: ->
#    return a.find({})
#  children: soop.children(A.schema)

Meteor.publishComposite 'dataComposite',
  find: -> a.find({ })
  children: [
    find: (x)->
      out = []
      for i in (new A(x, false, false)).a
        for j in i.b2
          out.push j._id
      console.log out
      c.find({_id: {$in: out}})
    ]

