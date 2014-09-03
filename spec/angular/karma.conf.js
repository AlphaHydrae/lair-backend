
var _ = require('underscore'),
    path = require('path');

var assets = require('./assets');

var files = _.inject(require('./assets'), function(memo, asset) {

  _.each(asset.dependencies, function(dep) {
    if (dep.logicalPath === 'lair.js') {
      memo.push('spec/angular/lair.js');
    } else {
      memo.push(dep.projectPath);
    }
  });

  return memo;
}, []);

files.push('spec/angular/support/**/*.js');
files.push('spec/angular/unit/**/*.spec.js');

module.exports = function(config) {
  config.set({

    basePath: '../../',

    files: files,

    autoWatch: true,

    frameworks: ['jasmine'],

    browsers: ['Firefox', 'Chrome'],

    plugins: [
      'karma-chrome-launcher',
      'karma-firefox-launcher',
      'karma-jasmine'
    ]
  });
};
