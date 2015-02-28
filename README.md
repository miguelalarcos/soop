SOOP
====

Simple Object Oriented Programming for Meteor.

Explanation
-----------

Use:

```coffee
class Car extends soop.Base
  @collection: car
  @schema :
    tag:
      type: Number

class Text extends soop.inLine
  @schema:
    text:
      type: String

class Complex extends soop.inLine
  @schema:
    r:
      type: Number
    i:
      type: Number
    t:
      type: Text

class Person extends soop.Base
  @collection: person
  @schema :
    firstName:
      type: String
    lastName:
      type: String
      optional: true
    cars:
      type: [[[Car]]]
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
    Person.find()


Template.home.events
  'click .new-person': (e,t)->
    p1 = new Person {firstName: 'Miguel', lastName:'Alarcos'}
    a1 = new Car(tag:5001)
    a2 = new Car(tag:7982)
    p1.cars = [[[a1, a2],[a1, a2]]]
    p1.numbers = [1,2,3,4,5]
    # p1.complex = new Complex({r:50, i:70, t: {text:'hola mundo'}})  # this expression is valid too

    p1.complex = new Complex
      r:50
      i:70
      t:
        new Text
          text: 'hola mundo'
    p1.save()
```

API
---

* ```soop.Base```
You inherit from this class to have a class that have a save method to save to the given collection.

* ```soop.inLine```
You inherit from this class to have a class that doesn't persist directly (it doesn't have a collection).

* ```soop.properties```
Is this code:
```coffee
properties = (self, props) -> Object.defineProperties self.prototype, props
```
Is used to create properties (setter and getter).

TODO
----
* Integrate with ```simple-schema```
* Philosophy:
  Is it a good idea to have that kind of OOP with Meteor?

Contributing
------------
* Help is welcome :)