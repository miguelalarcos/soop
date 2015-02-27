class HomeController extends RouteController
  waitOn: -> [Meteor.subscribe('persons'), Meteor.subscribe('cars')]

Router.map ->
  @route 'home',
    path: '/'
    controller: HomeController