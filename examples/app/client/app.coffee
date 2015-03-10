class HomeController extends RouteController
  waitOn: -> Meteor.subscribe 'dataComposite'
  data: ->
    return data: (new A(x) for x in a.find({}).fetch())


Router.map ->
  @route 'home',
    path: '/'
    controller: HomeController

Template.home.events
  'click button': (e,t) ->
    b1 = new B
      b: 'amstrad'
      b2: [new C(c:1000), new C(c:1001)]

    b2 = new B
      b : 'atari'
      b2: [new C(c:1002), new C(c:1003)]

    a1 = new A
      a: [b1, b2]

    a1.save()
