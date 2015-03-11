a.remove({})
c.remove({})
e.remove({})
g.remove({})
h.remove({})
i.remove({})

elem = new A
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

elem.save()