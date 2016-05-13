angular.module('lair.forms').directive('ngCompare', function() {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {
      ctrl.$validators.ngCompare = function(modelValue, viewValue) {

        var expected = $scope.$eval(attrs.ngCompare),
            actual = modelValue;

        if (!expected || !actual) {
          return true;
        }

        var op = attrs.ngCompareOp || 'eq';
        if (op == 'gt') {
          return actual > expected;
        } else if (op == 'gte') {
          return actual >= expected;
        } else if (op == 'lt') {
          return actual < expected;
        } else if (op == 'lte') {
          return actual <= expected;
        } else {
          return actual == expected;
        }
      };
    }
  };
});
