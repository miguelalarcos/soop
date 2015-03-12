@a = new Mongo.Collection "A"

class @B extends soop.InLine
  @schema:
    b1:
      type: Number

class @A extends soop.Base
  @collection: a
  @schema:
    a1:
      type: String
    a2:
      type: B

soop.attachSchema(A)
