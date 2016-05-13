angular.module('lair.users').directive('uniqueUserName', function(api, auth, $q, $rootScope) {
  return {
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {

      ctrl.$asyncValidators.uniqueUserName = function(modelValue) {

        // If the name is blank then there can be no name conflict.
        if (_.isBlank(modelValue)) {
          return $q.when();
        }

        return api({
          url: '/users',
          params: {
            name: modelValue,
            number: 1
          }
        }).then(function(res) {

          // The value is valid if no record is found or
          // if the record found is the one being modified.
          if (!res.data.length || res.data[0].id == $scope.modifiedUser.id) {
            return $q.when();
          } else {
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
