angular.module('lair.parts.edit', [])

  .controller('EditPartController', ['ApiService', '$log', '$q', '$scope', '$stateParams', function($api, $log, $q, $scope, $stateParams) {

    function fetchPart() {
      return $api.http({
        url: '/api/parts/' + $stateParams.partId
      }).then(function(res) {
        $scope.part = res.data;
        $scope.reset();
      }, function(res) {
        // TODO: handle error
        $log.warn('Could not fetch part ' + $stateParams.partId);
        $log.debug(res);
      });
    }

    function fetchItem() {
      return $api.http({
        url: '/api/items/' + $scope.part.itemId
      }).then(function(res) {
        $scope.item = res.data;
      }, function(res) {
        $log.warn('Could not fetch item ' + $scope.part.itemId);
        $log.debug(res);
      });
    }

    function fetchLanguages() {
      return $api.http({
        url: '/api/languages'
      }).then(function(res) {
        $scope.languages = res.data;
      }, function(res) {
        // TODO: handle error
        $log.warn('Could not fetch languages');
        $log.debug(res);
      });
    }

    $q.all($q.when().then(fetchPart).then(fetchItem), fetchLanguages());

    $scope.save = function() {
      $api.http({
        method: 'PATCH',
        url: '/api/parts/' + $stateParams.partId,
        data: $scope.editedPart
      }).then(function(res) {
        $scope.part = res.data;
        $scope.reset();
      }, function(res) {
        // TODO: handle error
        $log.warn('Could not update part ' + $stateParams.partId);
        $log.debug(res);
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
