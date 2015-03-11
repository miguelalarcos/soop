@a = new Mongo.Collection "A"
@c = new Mongo.Collection "C"

class @C extends soop.Base
  @collection: c
  @schema:
    c:
      type: Number

class @B extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: [[C]]

class @A extends soop.Base
  @collection: a
  @schema:
    a:
      type: [B]
