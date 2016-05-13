angular.module('lair.works.form').directive('uniqueCompanyName', function(api, auth, $q) {
  return {
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {

      ctrl.$asyncValidators.uniqueCompanyName = function(modelValue) {
        delete $scope.existingCompany;

        // If the name is blank then there can be no name conflict.
        if (_.isBlank(modelValue)) {
          return $q.when();
        }

        return api({
          url: '/companies',
          params: {
            name: modelValue,
            number: 1
          }
        }).then(function(res) {

          // The value is valid if no record is found or
          // if the record found is the one being modified.
          if (!res.data.length || res.data[0].id == $scope.company.id) {
            return $q.when();
          } else {
            $scope.existingCompany = res.data[0];
            return $q.reject();
          }
        }, function() {
          // consider value valid if uniqueness cannot be verified
          return $q.when();
        });
      };
    }
  };
});
