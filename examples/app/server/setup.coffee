a.remove({})
c.remove({})

c1 = new C
  c: 5
#c1.save()

c2 = new C
  c: 6
#c2.save()

c3 = new C
  c: 7
#c3.save()

c4 = new C
  c: 8
#c4.save()

b1 = new B
  b: 'insert coin'
  b2: [[c1, c2], [c3, c4]]
  #b2: [c1, c2]

b2 = new B
  b: 'game over!'
  b2: [[c1, c2], [c3, c4]]
  #b2:  [c3, c4]

a1 = new A
  a: [b1, b2]

a1.save()