class Car extends soop.Base
  @collection: car
  collection : car
  _schema :
    tag:
      type: Number

class Person extends soop.Base
  @collection: person
  collection : person
  _schema :
    firstName:
      type: String
    lastName:
      type: String
    cars:
      type: [Car]
  soop.properties @,
    fullName:
      get : ->
        "#{@firstName} #{@lastName}"
      set: (name) ->
        [firstName, lastName] = name.split ' '
        @['firstName'] = firstName
        @['lastName'] = lastName


p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}
a1 = new Car(tag:5)
a2 = new Car(tag:7)
p1.cars = [a1, a2]
p1.save()

Template.home.helpers
  items: ->
    Person.find()
  format0: (obj)->
    obj[0].tag
