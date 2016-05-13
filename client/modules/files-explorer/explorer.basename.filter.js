angular.module('lair.files.explorer').filter('basename', function() {
  return function(input) {
    return input ? input.replace(/.*\//, '') : input;
  };
});
