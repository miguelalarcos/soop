[![Build Status](https://travis-ci.org/miguelalarcos/soop.svg)](https://travis-ci.org/miguelalarcos/soop)

SOOP
====

Simple Object Oriented Programming for Meteor.

Explanation
-----------

(Please note that this is not production ready yet.)

Given:

```coffee
a = new Mongo.Collection 'TestA'
c = new Mongo.Collection 'TestC'

class C extends soop.Base
  @collection: c
  @schema:
    c:
      type: String
  dots: (word) -> @c + '...' + word

class B extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: C
    b3:
      type: [C]
      optional: true
    b4:
      type: [Number]
      optional: true
    b5:
      type: [[C]]

class A extends soop.Base
  @collection: a
  @schema:
    a:
      type: String
    a2:
      type: C
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
console.log a2.a3.b5[0][0].c.dots('hello') # -> atari...hello
```

and in the template:

```html
...
    {{this.dots 'hello'}}
...
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
        type: C
        optional: false
      a3:
        type: B # this is InLine
  ```
  When saved to Mongodb, the path *a2* will have the _id of that object (that is previously automatically saved), while path *a3* will have the object itself. It is only necessary to call *save* on the root object.
  When doing a *save* that implies an *update*, only the dirty attributes are in $set. If you set an attribute to *undefined*, it will go in $unset.
  This class have the next methods: *isValid*, *findOne* (class method), *save*, *remove* and *sync*.

  * isValid:
    returns a boolean indicating if the object is valid according to its schema.
  * findOne:
    you pass an _id and returns the object with this _id. Class method.
  * save:
    saves the object to Mongo. It can be an insert or an updated depending if the object has an _id or not.
  * remove:
    removes de objecto from Mongo.
  * sync:
    you call *sync* to update the object with the actual values on Mongo.

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
  [{path: attr that fails, valid: true or false, message: 'descriptive message in case of fail'}, ...]
  ```
  It is useful to know what exactly fails.

* array:

  wrap a normal array to have a method *set* (```set(index, value -> ```) to mark as dirty the index position of that array.

* soop.pCChildren:

  It's an useful function to obtain the children part of the ```publish-composite```, given a class.
   ```coffee
   pCChildren = (K) -> returns [{find: ..., children: ...}, ...]
   ```
* soop.attachSchema:

  You use like this at the root level:
  ```coffee
  soop.attachSchema(A)
  ```
  All collections involved are attached to its corresponding schema.

Look at the tests and examples for more information.

TODO
----
* Take in consideration that the insert, update or remove can fail, so do something.
* Philosophy:
  Is it a good idea to have that kind of OOP with Meteor?

Contributing
------------
* Help is welcome.

Issues
------
As far as I know, there is no weak references in javascript. So, I can not cached the objects in a dictionary (by its _id). So, be careful in this case:
```coffee
a = New A(a:8)
a.save()
a2 = A.findOne(a._id)
a is a2 # false, so if you modify 'a' you are not modifying 'a2'.
```
