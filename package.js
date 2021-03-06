Package.describe({
  name: 'miguelalarcos:soop',
  version: '0.6.5',
  summary: 'Simple Object Oriented Programming for Meteor',
  git: 'https://github.com/miguelalarcos/soop.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.2');
  api.use('coffeescript');
  api.use('tracker');
  api.use('underscore');
  api.use('aldeed:collection2@2.3.2', ['client', 'server']);
  api.addFiles('soop.coffee', ['client', 'server']);
  api.export('soop', ['client', 'server']);
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('tracker');
  api.use('miguelalarcos:soop');
  api.use('coffeescript');
  api.use('mongo', ['client', 'server']);
  api.use('underscore', 'client');
  api.use('practicalmeteor:munit', ['client', 'server']);
  api.addFiles('test-soop.coffee', 'client');
  api.addFiles('test-space.coffee', 'server');
  api.addFiles('test-sync.coffee', 'server');
  api.addFiles('test-functions.coffee', 'client');
  api.addFiles('test-functions2.coffee', 'client');
  api.addFiles('test-integration-collection2.coffee', 'server');
  api.addFiles('test-utils-server.coffee', 'server');
});

