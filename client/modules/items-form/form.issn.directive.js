angular.module('lair.items.form').directive('validIssn', function() {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {

      // Inspired from: http://neilang.com/articles/validate-an-issn-using-javascript/
      function isValid(issn) {
        issn = issn.toUpperCase().replace(/[^\dX]/g, '');
        if (issn.length != 8){
          return false;
        }

        var chars = issn.split('');
        if (chars[7].toUpperCase() == 'X'){
          chars[7] = 10;
        }

        var sum = 0;
        for (var i = 0; i < chars.length; i++) {
          sum += ((8 - i) * parseInt(chars[i]));
        };

        return ((sum % 11) == 0);
      }

      ctrl.$validators.validIssn = function(modelValue, viewValue) {
        if (!modelValue || !modelValue.length) {
          return true;
        }

        return isValid(modelValue);
      };
    }
  };
});

angular.module('lair.items.form').directive('validIssnFormat', function() {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {
      ctrl.$validators.validIssnFormat = function(modelValue, viewValue) {
        if (!modelValue || !modelValue.length) {
          return true;
        }

        var normalized = modelValue.toUpperCase();
        return !!normalized.match(/^\d{4}\-?\d{3}[\dX]$/);
      };
    }
  };
});
