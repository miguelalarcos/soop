@a = new Mongo.Collection "A"
@c = new Mongo.Collection "C"
@e = new Mongo.Collection "E"
@g = new Mongo.Collection "G"
@h = new Mongo.Collection "H"
@i = new Mongo.Collection "I"

class @D extends soop.InLine
  @schema:
    value:
      type: Number

class @E extends soop.Base
  @collection: e
  @schema:
      value:
        type: Number

class @F extends soop.InLine
    @schema:
      value:
        type: Number

class @G extends soop.Base
  @collection: g
  @schema:
      value:
        type: Number

class @C extends soop.Base
  @collection: c
  @schema:
    value1:
      type: F
    value2:
      type: G

class @B extends soop.InLine
  @schema:
    value1:
      type: D
    value2:
      type: E

class @I extends soop.Base
  @collection: i
  @schema:
    value:
      type: Number

class @H extends soop.Base
  @collection: h
  @schema:
    value1:
      type: I

class @A extends soop.Base
  @collection: a
  @schema:
    value1:
      type: B
    value2:
      type: C
    value3:
      type: [H]