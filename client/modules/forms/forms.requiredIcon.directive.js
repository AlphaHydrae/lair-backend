angular.module('lair.forms').directive('requiredIcon', function() {
  return {
    restrict: 'E',
    template: '<span class="glyphicon glyphicon-asterisk required-icon" uib-tooltip="{{ message }}" tooltip-append-to-body="true" />',
    scope: {
      message: '@'
    },
    controller: function($scope) {
      $scope.message = $scope.message || 'This field is required.';
    }
  };
});
