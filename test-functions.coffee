class C extends soop.Base
  #@collection: c
  @schema:
    c:
      type: String
    c2:
      type: [Number]
      optional: true

class B extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: C
      optional: true
    b3:
      type: [C]
      optional: true
    b4:
      type: [Number]
      optional: true
    b5:
      type: [[C]]
      optional: true

class A extends soop.Base
  #@collection: a
  @schema:
    a:
      type: String
    a2:
      type: C
      optional: true
    a3:
      type: B

class D2 extends soop.Base
  @collection: 'd'
  @schema:
    d:
      type: Number

class C2 extends soop.Base
  @collection: 'c'
  @schema:
    c:
      type: Number
    c2:
      type: [D2]

class B2 extends soop.InLine
  @schema:
    b:
      type: String
    b2:
      type: [C2]

class A2 extends soop.Base
  @collection: 'a'
  @schema:
    a:
      type: [B2]

describe 'test nextSchemaAttr', ->
  it 'test A->C', (test) ->
    ns = soop._nextSchemaAttr(A.schema, 'a2')
    test.equal ns, C.schema

  it 'test A->B-C', (test)->
    ns = soop._nextSchemaAttr(A.schema, 'a3')
    ns = soop._nextSchemaAttr(ns, 'b5')
    test.equal ns, C.schema

describe 'test traverse', ->
  it 'test basic', (test) ->
    a = new A
      a3: new B
        b3: [new C(c:'hello'), new C(c:'world')]
    subdocs = soop._traverseSubDocs(a, 'a3.b3.$.c')
    test.equal subdocs, ['hello', 'world']

  it 'traverse basic2', (test) ->
    a = new A2
      a: [
        new B2
          b: 'hello'
          b2: [
            new C2
              c2: [
                new D2
                  d: 5
              ]
          ]
      ]
    subdocs = soop._traverseSubDocs(a, 'a.$.b')
    test.equal subdocs, ['hello']

  it 'traverse basic3', (test) ->
    c = new C2
      c2: [
        new D2
          d: 5
      ]

    subdocs = soop._traverseSubDocs(c, 'c2.$.d')
    test.equal subdocs, [5]

describe 'test children', ->

  it 'test basic', (test) ->
    docs =  soop._children(A2, A2.collection, '', A2)
    test.equal docs[0].collection, 'c'
    test.equal docs[0].path, "a.$.b2"
    test.equal docs[0].children[0].collection, 'd'
    test.equal docs[0].children[0].path, "c2"

