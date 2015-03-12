@a = new Mongo.Collection "A"

sc_b =
  b1:
    type: Number

class @B extends soop.InLine
  @schema: sc_b

sc_a =
  a1:
    type: String
  a2:
    type: B

class @A extends soop.Base
  @collection: a
  @schema: sc_a

a.attachSchema(sc_a)
