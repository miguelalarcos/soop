class HomeController extends RouteController
  waitOn: -> Meteor.subscribe 'dataComposite'
  data: ->
    z = (new A(x) for x in a.find({}).fetch())
    #console.log z
    return data: z

Router.map ->
  @route 'home',
    path: '/'
    controller: HomeController