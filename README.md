[![Build Status](https://travis-ci.org/miguelalarcos/soop.svg)](https://travis-ci.org/miguelalarcos/soop)

SOOP
====

Simple Object Oriented Programming for Meteor.

Explanation
-----------

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

API
---

* soop.Base

  Base class for persistence.

  example:
  ```coffee
  class A extends soop.Base
    @collection: a
    @schema:
      a:
        type: String
      a2:
        type: C  # this is InLine
        optional: false
      a3:
        type: B
  ```
  When saved to Mongo, the path *a3* will have the _id of that object, while path *a2* will have the object itself. It is only necessary to call *save* on the root object.
  When doing a *save* that implies an *update*, only the dirty attributes are in $set. If you set an attribute to *undefined*, it will go in $unset.
  This class have a *isValid* method.

* soop.InLine

  Base class for inline object.

  example:
  ```coffee
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
  ```

* soop.validate:

  ```coffee
  validate = (obj) -> returns an array of this class:
  [{k: attr that fails, v: true or false, m: 'descriptive message in case of fail'}, ...]
  ```
  It is useful to know what exactly fails.

Look at the tests for more information.

TODO
----
* Integrate with ```simple-schema```
* Philosophy:
  Is it a good idea to have that kind of OOP with Meteor?

Contributing
------------
* Help is welcome.