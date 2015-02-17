angular.module('lair.parts.edit', ['lair.forms'])

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

    function fetchPublishers() {
      return $api.http({
        url: '/api/bookPublishers'
      }).then(function(res) {
        $scope.publishers = res.data;
      }, function(res) {
        $log.warn('Could not fetch book publishers');
        $log.debug(res);
      });
    }

    function fetchEditions() {
      return $api.http({
        url: '/api/partEditions'
      }).then(function(res) {
        $scope.editions = res.data;
      }, function(res) {
        $log.warn('Could not fetch part editions');
        $log.debug(res);
      });
    }

    function fetchFormats() {
      return $api.http({
        url: '/api/partFormats'
      }).then(function(res) {
        $scope.formats = res.data;
      }, function(res) {
        $log.warn('Could not fetch part formats');
        $log.debug(res);
      });
    }

    function fetchItem() {
      return $api.http({
        url: '/api/items/' + $scope.part.itemId
      }).then(function(res) {
        $scope.item = res.data;
        $scope.items = [ $scope.item ];
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

    $scope.editedPart = {};

    $q.all($q.when().then(fetchPart).then(fetchItem), fetchEditions(), fetchFormats(), fetchLanguages(), fetchPublishers());

    $scope.fetchItems = function(search) {
      if (!search || !search.trim().length) {
        $scope.items = [ $scope.item ];
        return;
      }

      $api.http({
        url: '/api/items',
        params: {
          pageSize: 100,
          search: search
        }
      }).then(function(res) {
        $scope.items = res.data;
      }, function(res) {
        $log.warn('Could not fetch items matching "' + search + '"');
        $log.debug(res);
      });
    };

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
