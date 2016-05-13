angular.module('lair.items.form').directive('validIsbn', function() {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {
      ctrl.$validators.validIsbn = function(modelValue, viewValue) {
        if (!modelValue || !modelValue.length) {
          return true;
        }

        var isbn = ISBN.parse(modelValue);
        if (!isbn || !isbn.isValid()) {
          return false;
        }

        return isbn.codes.check == (isbn.isIsbn13() ? isbn.codes.check13 : isbn.codes.check10);
      };
    }
  };
});

angular.module('lair.items.form').directive('validIsbnFormat', function() {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {
      ctrl.$validators.validIsbnFormat = function(modelValue, viewValue) {
        if (!modelValue || !modelValue.length) {
          return true;
        }

        var normalized = modelValue.toUpperCase().replace(/[^\dX]+/g, '');
        return !!normalized.match(/^\d{9}[\dX]$/) || !!normalized.match(/^\d{13}$/);
      };
    }
  };
});
