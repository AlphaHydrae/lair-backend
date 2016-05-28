angular.module('lair.companies').directive('companyName', function() {
  return {
    restrict: 'E',
    scope: {
      company: '='
    },
    template: '{{ buildName(company) }}',
    controller: function($scope) {
      $scope.buildName = function(company) {
        if (!company) {
          return '-';
        }

        return company.name;
      };
    }
  };
});
