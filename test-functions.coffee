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
      #optional: true
    c2:
      type: [D2]
      optional: true

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
    subdocs = soop.traverseSubDocs(a, 'a3.b3.$.c')
    test.equal subdocs, ['hello', 'world']

  it 'traverse nested', (test) ->
    a = new A2
      a:
        [new B2
          b: 'hello'
          b2:
            [new C2
              c: -1
              c2:
                [new D2
                  d: 5]
            new C2
              c: -2
            ]
        new B2
          b: 'world'
          b2:
            [new C2
              c2:
                [new D2
                  d: 7]
            ]
        ]
    subdocs = soop.traverseSubDocs(a, 'a.$.b')
    test.equal subdocs, ['hello', 'world']
    subdocs = soop.traverseSubDocs(a, 'a.$.b2.$.c2.$.d')
    test.equal subdocs, [5, 7]
    #test.isFalse a.isValid()
    #a.a[1].b2[0].c = -11
    #test.isTrue a.isValid()

  it 'traverse basic3', (test) ->
    c = new C2
      c2: [
        new D2
          d: 5
      ]

    subdocs = soop.traverseSubDocs(c, 'c2.$.d')
    test.equal subdocs, [5]

describe 'test children', ->

  it 'test basic', (test) ->
    docs =  soop._children(A2, A2.collection, '', A2)
    test.equal docs[0].collection, 'c'
    test.equal docs[0].path, "a.$.b2"
    test.equal docs[0].children[0].collection, 'd'
    test.equal docs[0].children[0].path, "c2"

