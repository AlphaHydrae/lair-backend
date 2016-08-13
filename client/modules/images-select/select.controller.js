angular.module('lair.images.select').controller('SelectImageCtrl', function(api, $log, $uibModalInstance, $scope, $timeout) {

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

  if ($scope.imageSearchResource && $scope.imageSearchResourceId) {
    $scope.loadingImageSearch = true;

    api({
      url: '/imageSearches',
      params: {
        resource: $scope.imageSearchResource,
        resourceId: $scope.imageSearchResourceId,
        withResults: 1,
        number: 1
      }
    }).then(function(res) {
      if (res.data.length) {
        $scope.loadingImageSearch = false;
        $scope.imageSearch = res.data[0];
        $scope.query = $scope.imageSearch.query;
        $scope.engine = $scope.imageSearch.engine;
      } else {
        searchImages();
      }
    }, function() {
      $scope.loadingImageSearch = false;
    });
  }

  $scope.select = function(image) {
    $uibModalInstance.close(image);
  };

  $scope.searchImages = function() {
    if ($scope.imageSearch && $scope.query == $scope.imageSearch.query && $scope.engine == $scope.imageSearch.engine && !confirm('Are you sure you want to perform the same search for "' + $scope.query + '" again?')) {
      return;
    }

    searchImages();
  };

  function searchImages() {

    var data = {};
    if ($scope.imageSearchResource && $scope.imageSearchResourceId) {
      data.resource = $scope.imageSearchResource;
      data.resourceId = $scope.imageSearchResourceId;
    }

    api({
      method: 'POST',
      url: '/imageSearches',
      params: {
        withResults: 1
      },
      data: _.extend(data, {
        query: $scope.query,
        engine: $scope.engine
      })
    }).then(function(res) {
      $scope.loadingImageSearch = false;
      $scope.imageSearch = res.data;

      $scope.engine = $scope.imageSearch.engine;
      if (!$scope.query) {
        $scope.query = $scope.imageSearch.query;
      }

      updateRateLimit(res);
    }, function(res) {
      $scope.loadingImageSearch = false;

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
});
