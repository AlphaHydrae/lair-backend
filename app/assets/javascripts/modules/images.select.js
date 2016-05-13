angular.module('lair.images.select', ['lair.api'])

  .controller('SelectImageCtrl', function(api, $log, $modalInstance, $scope, $timeout) {

    $scope.manualImage = {};
    $scope.manualImageNotFound = false;

    $scope.onManualImageNotFound = function() {
      $scope.manualImageNotFound = true;
    };

    $scope.$watch('manualImage.url', function() {
      $scope.manualImageNotFound = false;
      $scope.manualImage.thumbnail = {
        url: $scope.manualImage.url
      };
    });

    function updateRateLimit(response) {
      $scope.rateLimit = response.rateLimit();

      if ($scope.rateLimit.isExceeded()) {
        $timeout(function() {
          $scope.rateLimit.clear();
        }, $scope.rateLimit.reset.getTime() - new Date().getTime() + 1000);
      }
    }

    $scope.engines = [
      { name: 'bingSearch', label: 'Bing' },
      { name: 'googleCustomSearch', label: 'Google' }
    ];

    $scope.engine = $scope.engines[0].name;

    if ($scope.mainImageSearchResource) {
      api({
        method: 'PATCH',
        url: $scope.mainImageSearchResource
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
    }

    $scope.select = function(image) {
      $modalInstance.close(image);
    };

    $scope.searchImages = function() {
      if ($scope.imageSearch && $scope.query == $scope.imageSearch.query && $scope.engine == $scope.imageSearch.engine && !confirm('Are you sure you want to perform the same search for "' + $scope.query + '" again?')) {
        return;
      }

      api({
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
  })
;
