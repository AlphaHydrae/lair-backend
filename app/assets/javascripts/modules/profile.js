angular.module('lair.profile', [ 'lair.api', 'lair.forms' ])

  .controller('ProfileCtrl', function(api, auth, forms, $scope) {

    $scope.user = $scope.currentUser;

    $scope.save = saveProfile;
    $scope.reset = resetModifiedUser;
    $scope.$watch('user', resetModifiedUser);

    $scope.changed = function() {
      return !forms.dataEquals($scope.user, $scope.modifiedUser);
    };

    function saveProfile() {
      api({
        method: 'PATCH',
        url: '/users/' + $scope.user.id,
        data: $scope.modifiedUser
      }).then(function(res) {
        $scope.user = res.data;
        auth.updateCurrentUser(res.data);
      });
    }

    function resetModifiedUser() {
      $scope.modifiedUser = angular.copy($scope.user);
    }
  })

  .directive('uniqueUserName', function(api, auth, $q, $rootScope) {
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
  })

;
