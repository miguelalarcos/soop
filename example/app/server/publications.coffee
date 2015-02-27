Meteor.publish 'persons', -> person.find({})
Meteor.publish 'cars', -> car.find({})