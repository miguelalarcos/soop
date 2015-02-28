Package.describe({
  name: 'miguelalarcos:soop',
  version: '0.1.0',
  summary: 'Simple Object Oriented Programming for Meteor',
  git: 'https://github.com/miguelalarcos/soop.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.2');
  api.use('coffeescript');
  api.addFiles('soop.coffee', 'client');
  api.export('soop', 'client');
});

/*Package.onTest(function(api) {
  api.use('tinytest');
  api.use('miguelalarcos:soop');
  api.addFiles('miguelalarcos:soop-tests.js');
});
*/
