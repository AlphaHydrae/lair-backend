angular.module('lair.mediaIdent.dialog').controller('MediaIdentDialogCtrl', function(api, busy, $modalInstance, $scope) {

  busy($scope, true);

  fetchMediaSource().then(setSearch);

  var settings = $scope.settings = {
    next: true,
    similarSearch: false
  };

  $scope.selectSearchResult = function(result) {
    if (settings.similarSearch) {
      return;
    }

    settings.selectedUrl = result.url;
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
        selectedUrl: settings.selectedUrl
      }
    }).then(function(res) {

      $scope.search.selectedUrl = settings.selectedUrl;

      $modalInstance.close(_.extend({
        mediaDirectory: $scope.mediaDirectory,
        mediaSearch: res.data
      }, _.pick(settings, 'next')));
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
    return performNewSearch().then(function(search) {
      $scope.search = search;
      autoSelectFirstResult(search);
      settings.similarSearch = false;
      return search;
    });
  };

  $scope.useSimilarSearch = function() {
    return api({
      method: 'POST',
      url: '/media/searches/' + $scope.search.id + '/directoryIds',
      data: [ $scope.mediaDirectory.id ]
    }).then(function(res) {

      $scope.search.directoryIds = res.data;
      settings.similarSearch = false;

      if ($scope.search.selectedUrl) {
        $modalInstance.close(_.extend({
          mediaDirectory: $scope.mediaDirectory,
          mediaSearch: $scope.search
        }, _.pick(settings, 'next')));
      } else {
        autoSelectFirstResult($scope.search);
      }

      return res.data;
    });
  };

  function setSearch() {
    return fetchExistingSearch().then(function(search) {
      return search || fetchSimilarSearch().then(function(search) {
        if (search) {
          settings.similarSearch = true;
          return search;
        }
      });
    }).then(function(search) {
      return search || performNewSearch();
    }).then(function(search) {
      if (search && !settings.similarSearch) {
        autoSelectFirstResult(search);
      }

      return search;
    }).then(function(search) {
      $scope.search = search;
      if (search && search.selectedUrl) {
        settings.selectedUrl = search.selectedUrl;
      }
    }).finally(_.partial(busy, $scope, false));
  }

  function autoSelectFirstResult(search) {
    if (!search.selectedUrl && search.resultsCount) {
      settings.selectedUrl = search.results[0].url;
    }
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
