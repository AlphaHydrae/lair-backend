angular.module('lair.images.select', ['lair.api'])

  .controller('SelectImageCtrl', ['ApiService', '$log', '$modalInstance', '$scope', '$timeout', function($api, $log, $modalInstance, $scope, $timeout) {

    function updateRateLimit(response) {
      $scope.rateLimit = $api.rateLimit(response);

      if ($scope.rateLimit.isExceeded()) {
        $timeout(function() {
          $scope.rateLimit.clear();
        }, $scope.rateLimit.reset.getTime() - new Date().getTime() + 1000);
      }
    }

    $scope.engines = [
      { name: 'bing', label: 'Bing' }
    ];

    var method = 'POST',
        url = $scope.imageSearchesResource;

    if ($scope.mainImageSearchResource) {
      method = 'PATCH';
      url = $scope.mainImageSearchResource;
    }

    $api.http({
      method: method,
      url: url
    }).then(function(res) {
      $scope.imageSearch = res.data;
      $scope.query = $scope.imageSearch.query;
      $scope.engine = $scope.imageSearch.engine;
      updateRateLimit(res);
    }, function(res) {
      if (res.status == 429) {
        $scope.query = $scope.imageSearch.query;
        $scope.engine = $scope.imageSearch.engine;
        updateRateLimit(res);
      } else {
        $log.warn('Could not perform image search');
        $log.debug(res);
      }
    });

    $scope.select = function(image) {
      $modalInstance.close(image);
    };

    $scope.searchImages = function() {
      if ($scope.query == $scope.imageSearch.query && $scope.engine == $scope.imageSearch.engine && !confirm('Are you sure you want to perform the same search for "' + $scope.query + '" again?')) {
        return;
      }

      $api.http({
        method: 'POST',
        url: $scope.imageSearchesResource,
        data: {
          query: $scope.query,
          engine: $scope.engine
        }
      }).then(function(res) {
        $scope.imageSearch = res.data;
        updateRateLimit(res);
      }, function(res) {
        if (res.status == 429) {
          $scope.query = $scope.imageSearch.query;
          $scope.engine = $scope.imageSearch.engine;
          updateRateLimit(res);
        } else {
          $log.warn('Could not perform image search');
          $log.debug(res);
        }
      });
    };
  }])
;
