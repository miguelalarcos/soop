Meteor.publishComposite 'dataComposite',
  find: ->
    return a.find({})
  children: soop.pCChildren(A)

###
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


Meteor.publishComposite 'dataComposite',
  find: -> a.find({ })
  children: [
    find: (x)->
      lista = (new A(x, false, false)).a
      lista = (x.b2 for x in lista)
      lista = _.flatten(lista)
      console.log lista
      c.find({_id: {$in: lista}})
  ]

###