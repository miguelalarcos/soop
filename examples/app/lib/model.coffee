@a = new Mongo.Collection "A"
@b = new Mongo.Collection "B"
@c = new Mongo.Collection "C"

class @B extends soop.InLine
  @schema:
    b:
      type: String

class @A extends soop.Base
  @collection: a
  @schema:
    a:
      type: [B]
