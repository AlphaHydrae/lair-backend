angular.module('lair.parts.edit', [])

  .controller('EditPartController', ['ApiService', '$log', '$scope', '$stateParams', function($api, $log, $scope, $stateParams) {

    $api.http({
      url: '/api/parts/' + $stateParams.partId
    }).then(function(response) {
      $scope.part = response.data;
      $scope.reset();
    }, function(response) {
      // TODO: handle error
      $log.warn('Could not fetch part ' + $stateParams.partId);
      $log.debug(response);
    });

    $api.http({
      url: '/api/languages'
    }).then(function(response) {
      $scope.languages = response.data;
    }, function(response) {
      // TODO: handle error
      $log.warn('Could not fetch languages');
      $log.debug(response);
    });

    $scope.save = function() {
      $api.http({
        method: 'PATCH',
        url: '/api/parts/' + $stateParams.partId,
        data: $scope.editedPart
      }).then(function(response) {
        $scope.part = response.data;
        $scope.reset();
      }, function(response) {
        // TODO: handle error
        $log.warn('Could not update part ' + $stateParams.partId);
        $log.debug(response);
      });
    };

    $scope.reset = function() {
      $scope.editedPart = angular.copy($scope.part);
    };

    $scope.partChanged = function() {
      return !angular.equals($scope.part, $scope.editedPart);
    };
  }])
;
