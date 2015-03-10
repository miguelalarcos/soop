Package.describe({
  name: 'miguelalarcos:soop',
  version: '0.3.4',
  summary: 'Simple Object Oriented Programming for Meteor',
  git: 'https://github.com/miguelalarcos/soop.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.2');
  api.use('coffeescript');
  api.addFiles('soop.coffee', ['client', 'server']);
  api.export('soop', ['client', 'server']);
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('miguelalarcos:soop');
  api.use('coffeescript');
  api.use('mongo', ['client', 'server']);
  api.use('underscore', 'client');
  api.use('practicalmeteor:munit', 'client');
  api.addFiles('soop-tests.coffee', 'client');
  api.addFiles('test-functions.coffee', 'client');
  api.addFiles('soop-tests-server.coffee', 'server');
});

