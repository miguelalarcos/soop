class HomeController extends RouteController
  waitOn: -> Meteor.subscribe 'dataComposite'
  data: ->
    data: (new A(x) for x in a.find({}).fetch())

Router.map ->
  @route 'home',
    path: '/'
    controller: HomeController