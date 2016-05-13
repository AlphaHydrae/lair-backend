angular.module('lair.forms').directive('formError', function() {
  return {
    restrict: 'A',
    scope: {
      formError: '=',
      formErrorDirty: '@'
    },
    transclude: true,
    template: '<ng-transclude />',
    link: function($scope, element, attrs) {
      $scope.setHasError = function(hasError) {
        element[hasError ? 'addClass' : 'removeClass']('has-error');
      };
    },
    controller: function($scope) {
      $scope.$watch(function() {
        return $scope.formErrorDirty !== undefined ? $scope.$eval($scope.formErrorDirty) : false;
      }, function(value) {
        $scope.formErrorDirtyEval = value;
      });

      $scope.$watch(function() {
        return $scope.formError && (!$scope.formErrorDirtyEval || $scope.formError.$dirty) && $scope.formError.$invalid;
      }, function(invalid) {
        $scope.setHasError(invalid);
      });
    }
  };
});
