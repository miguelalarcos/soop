class @D extends soop.InLine
  @schema:
    value:
      type: Number

class @E extends soop.Base
  @collection: 'e'
  @schema:
    value:
      type: Number

class @F extends soop.InLine
  @schema:
    value:
      type: Number

class @G extends soop.Base
  @collection: 'g'
  @schema:
    value:
      type: Number

class @C extends soop.Base
  @collection: 'c'
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
  @collection: 'i'
  @schema:
    value:
      type: Number

class @H extends soop.Base
  @collection: 'h'
  @schema:
    value1:
      type: I

class @A extends soop.Base
  @collection: 'a'
  @schema:
    value1:
      type: B
    value2:
      type: C
    value3:
      type: [H]

a = new A
  value1: new B
    value1: new D
      value: 0
    value2: new E
      value: 1
  value2: new C
    value1: new F
      value: 2
    value2: new G
      value: 3
  value3: [new H(value1: new I(value: -1))]

docs =  soop._children(A, A.collection, '', A)

remove_point = (path) ->
  if /^\./.test(path)
    path = path[1..]
  return path

describe 'basic suite', ->
  it 'test children', (test) ->

    test.equal docs[0].collection, 'e'
    test.equal remove_point(docs[0].path), "value1.value2"
    test.equal docs[0].children, []

  it 'test children2', (test) ->
    test.equal docs[1].collection, 'c'
    test.equal remove_point(docs[1].path), "value2"
    test.equal docs[1].children[0].collection, 'g'
    test.equal remove_point(docs[1].children[0].path), "value2"

  it 'test children3', (test) ->
    test.equal docs[2].collection, 'h'
    test.equal remove_point(docs[2].path), "value3"
    test.equal docs[2].children[0].collection, 'i'
    test.equal remove_point(docs[2].children[0].path), "value1"
