class Car extends soop.Base
  @collection: car
  @schema :
    tag:
      type: Number

class Complex extends soop.inLine
  @schema:
    a:
      type: Number
    i:
      type: Number

class Person extends soop.Base
  @collection: person
  @schema :
    firstName:
      type: String
    lastName:
      type: String
      optional: true
    cars:
      type: [[Car]]
    numbers:
      type: [Number]
    complex:
      type: Complex


  soop.properties @,
    fullName:
      get : ->
        "#{@firstName} #{@lastName}"
      set: (name) ->
        [firstName, lastName] = name.split ' '
        @['firstName'] = firstName
        @['lastName'] = lastName


Template.home.helpers
  items: ->
    p = Person.find()
    console.log p
    p
  #formatCars: (objs)->
  #  ret = ''
  #  for obj in (objs or [])
  #    ret += obj.tag + ':'
  #  ret

Template.home.events
  'click .new-person': (e,t)->
    p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}
    a1 = new Car(tag:5001)
    a2 = new Car(tag:7982)
    p1.cars = [[a1, a2],[a1, a2]]
    p1.numbers = [1,2,3,4,5]
    p1.complex = new Complex({a:50, i:70})
    p1.save()
