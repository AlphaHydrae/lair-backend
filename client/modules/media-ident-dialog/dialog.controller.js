angular.module('lair.mediaIdent.dialog').controller('MediaIdentDialogCtrl', function(api, busy, $modalInstance, $scope) {

  busy($scope, true);

  fetchMediaSource().then(setSearch);

  $scope.settings = {
    next: true
  };

  $scope.selectSearchResult = function(result) {
    $scope.search.selectedUrl = result.url;
  };

  $scope.goToNextSearch = function() {
    $modalInstance.close({
      mediaDirectory: $scope.mediaDirectory,
      next: true
    });
  };

  $scope.saveSelectedSearchResult = function() {
    return api({
      method: 'PATCH',
      url: '/media/searches/' + $scope.search.id,
      data: {
        selectedUrl: $scope.search.selectedUrl
      }
    }).then(function(res) {
      $modalInstance.close(_.extend({
        mediaDirectory: $scope.mediaDirectory,
        mediaSearch: res.data
      }, _.pick($scope.settings, 'next')));
    });
  };

  $scope.refresh = function() {
    return api({
      method: 'POST',
      url: '/media/searches/' + $scope.search.id + '/results'
    }).then(function(res) {
      $scope.search.new = true;
      $scope.search.results = res.data;
    });
  };

  $scope.runNewSearch = function() {

  };

  $scope.useSimilarSearch = function() {
    return api({
      method: 'POST',
      url: '/media/searches/' + $scope.similarSearch.id + '/directoryIds',
      data: [ $scope.mediaDirectory.id ]
    }).then(function(res) {
      $scope.similarSearch.directoryIds = res.data;
      $scope.search = $scope.similarSearch;
      delete $scope.similarSearch;
      return res.data;
    });
  };

  function setSearch() {
    return fetchExistingSearch().then(function(search) {
      if (search) {
        $scope.search = search;
        return search;
      }

      return fetchSimilarSearch().then(function(search) {
        if (search) {

          $scope.similarSearch = search;
          if ($scope.similarSearch.selectedUrl) {
            $scope.similarSearch.selectedResult = _.find($scope.similarSearch.results, { url: $scope.similarSearch.selectedUrl });
          }

          return search;
        }

        return performNewSearch().then(function(search) {
          $scope.search = search;
          if (!$scope.search.selectedUrl && search.resultsCount) {
            $scope.search.selectedUrl = search.results[0].url;
          }
        });
      });
      return search || fetchSimilarSearch();
    }).finally(_.partial(busy, $scope, false));
  }

  function fetchExistingSearch() {
    return api({
      url: '/media/searches',
      params: {
        number: 1,
        include: 'results',
        directoryId: $scope.mediaDirectory.id
      }
    }).then(function(res) {
      return _.first(res.data);
    });
  }

  function fetchSimilarSearch() {

    var scanPath = _.find($scope.mediaSource.scanPaths, function(scanPath) {
      return $scope.mediaDirectory.path.indexOf(scanPath.path) === 0;
    });

    var params = {
      number: 1,
      include: 'results',
      query: $scope.mediaDirectory.path.replace(/^.+\//, '')
    };

    if (scanPath) {
      params.category = scanPath.category;
    }

    return api({
      url: '/media/searches',
      params: params
    }).then(function(res) {
      return _.first(res.data);
    });
  }

  function performNewSearch() {
    return api({
      method: 'POST',
      url: '/media/searches',
      data: {
        directoryIds: [ $scope.mediaDirectory.id ]
      },
      params: {
        include: 'results'
      }
    }).then(function(res) {
      res.data.new = true;
      return res.data;
    });
  }

  function fetchMediaSource() {
    return api({
      url: '/media/sources/' + $scope.mediaDirectory.sourceId,
      params: {
        include: [ 'scanPaths', 'user' ]
      }
    }).then(function(res) {
      $scope.mediaSource = res.data;
      return res.data;
    });
  }
});
