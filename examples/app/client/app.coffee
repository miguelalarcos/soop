c = new C()
c.c = 8

class HomeController extends RouteController
  waitOn: -> Meteor.subscribe 'dataComposite'
  data: ->
    return {
    data: (new A(x) for x in a.find({}).fetch())
    element: c
    }

Router.map ->
  @route 'home',
    path: '/'
    controller: HomeController

Template.home.events
  'click .add': (e,t) ->
    b1 = new B
      b: 'amstrad'
      b2: [[new C(c:1000), new C(c:1001)],[new C(c:1002), new C(c:1003)]]

    b2 = new B
      b : 'atari'
      b2: [[new C(c:1002), new C(c:1003)],[new C(c:1002), new C(c:1003)]]

    a1 = new A
      a: [b1, b2]

    a1.save()

  'click .change': (e,t)->
    _id = c.findOne()._id
    elem = C.findOne(_id)
    elem.c = 0
    elem.save()

  'click .changeC': (e, t)->
    c.c = c.c + 1
    console.log c

