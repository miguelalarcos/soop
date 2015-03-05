[![Build Status](https://travis-ci.org/miguelalarcos/soop.svg)](https://travis-ci.org/miguelalarcos/soop)

SOOP
====

Simple Object Oriented Programming for Meteor.

Explanation
-----------

Look at the tests.

More soon :)

Given:

```coffee
a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: String

class B extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: C
    b3:
      type: [C]
    b4:
      type: [Number]
    b5:
      type: [[C]]

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: String
    a2:
      type: C
      optional: false
    a3:
      type: B
```

You can do things like:

```coffee
a1 = new A
  a: 'hello world'
  a2: new C
    c: 'insert coin'
  a3: new B
    b: 'game over!'
    b2: new C
      c: 'amstrad'
    b5: [[new C c:'atari']]

a1.save()
a2 = A.findOne(a1._id)
console.log a2.a3.b5[0][0].c # -> atari
```

TODO
----
* Integrate with ```simple-schema```
* Philosophy:
  Is it a good idea to have that kind of OOP with Meteor?

Contributing
------------
* Help is welcome.