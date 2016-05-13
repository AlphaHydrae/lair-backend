angular.module('lair.collections').directive('uniqueCollectionName', function(api, auth, $q, $rootScope) {
  return {
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {

      ctrl.$asyncValidators.uniqueCollectionName = function(modelValue, viewValue) {

        // If the name is blank then there can be no name conflict.
        if (_.isBlank(modelValue)) {
          return $q.when();
        }

        return api({
          url: '/collections',
          params: {
            userId: auth.currentUser.id,
            name: modelValue,
            number: 1
          }
        }).then(function(res) {

          // The value is valid if no record is found or
          // if the record found is the one being modified.
          if (!res.data.length || res.data[0].id == $scope.modifiedCollection.id) {
            return;
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
