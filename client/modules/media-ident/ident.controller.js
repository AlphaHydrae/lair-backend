angular.module('lair.mediaIdent').controller('MediaIdentCtrl', function(api, auth, $location, mediaIdentDialog, $q, $scope, scrapers, $stateParams, tables, $timeout) {

  $scope.mediaIdentList = {
    records: [],
    httpSettings: {
      url: '/media/files',
      params: {
        type: 'directory',
        nfo: 0,
        linked: 0,
        include: 'mediaSearch',
        mediaSearchCompleted: $stateParams.completed ? '*' : 0
      }
    },
    infiniteOptions: {
      enabled: false
    }
  };

  var route = $scope.route = _.pick($stateParams, 'source', 'directory', 'completed');

  fetchMediaSources();

  $scope.$watch('route', onSelectionChanged, true);

  $scope.$on('$locationChangeSuccess', function() {

    var search = $location.search();

    if (search.source != route.source) {
      route.source = search.source;
    }

    if (search.directory != route.directory) {
      route.directory = search.directory;
    }

    if (search.completed != route.completed) {
      route.completed = search.completed;
    }
  });

  $scope.identifyMedia = function(directory) {
    route.directory = directory.path;
  };

  $scope.showSupportedScrapers = function() {
    scrapers.openSupportModal($scope);
  };

  function onSelectionChanged(newRoute, oldRoute) {

    var sourceChanged = newRoute.source != oldRoute.source,
        directoryChanged = newRoute.directory != oldRoute.directory,
        completedChanged = newRoute.completed != oldRoute.completed;

    if (sourceChanged) {
      $location.search('source', newRoute.source);
      updateMediaSource(newRoute.source);
    } else if (newRoute.source) {
      updateMediaSource(newRoute.source);
    }

    if (directoryChanged) {
      $location.search('directory', newRoute.directory);
      if (newRoute.directory) {
        identifyMedia(newRoute.directory);
      } else {
        closeMediaIdentDialog();
      }
    } else if (newRoute.directory) {
      identifyMedia(newRoute.directory);
    }

    if (completedChanged) {
      $location.search('completed', newRoute.completed);
      $scope.mediaIdentList.httpSettings.params.mediaSearchCompleted = newRoute.completed ? '*' : 0;
    }
  }

  function identifyMedia(path) {
    closeMediaIdentDialog();

    fetchMediaDirectory(route.source, path).then(function(directory) {
      if (!directory) {
        delete route.directory;
        return;
      }

      $scope.mediaIdentDialog = mediaIdentDialog.open($scope, {
        mediaDirectory: directory
      });

      $scope.mediaIdentDialog.result.then(function(result) {
        if (result.mediaSearch) {
          var matchingDirectory = _.find($scope.mediaIdentList.records, { id: directory.id });
          if (matchingDirectory) {
            matchingDirectory.mediaSearch = result.mediaSearch;
            if (!route.completed && result.mediaSearch.selectedUrl) {
              $timeout(function() {
                $scope.mediaIdentList.records.splice($scope.mediaIdentList.records.indexOf(matchingDirectory), 1);
              }, 1);
            }
          }
        }

        if (result.mediaDirectory && result.next) {
          performNextSearch(result.mediaDirectory);
        }
      }).finally(function() {
        delete route.directory;
      });
    });
  }

  function closeMediaIdentDialog() {
    if ($scope.mediaIdentDialog) {
      $scope.mediaIdentDialog.dismiss();
      delete $scope.mediaIdentDialog;
    }
  }

  function performNextSearch(directory) {

    var directories = $scope.mediaIdentList.records,
        n = directories.length;

    var index = directories.indexOf(_.find(directories, { id: directory.id }));
    if (index < 0 || index >= n - 1) {
      return;
    }

    var nextDirectory;

    do {
      index++;
      nextDirectory = directories[index];
    } while (nextDirectory && nextDirectory.mediaSearch && nextDirectory.mediaSearch.selectedUrl);

    if (nextDirectory) {
      $timeout(function() {
        $scope.identifyMedia(nextDirectory);
      }, 1);
    }
  }

  function updateMediaSource(id) {
    return fetchMediaSource(id).then(function(source) {

      var params = $scope.mediaIdentList.httpSettings.params;
      _.extend(params, {
        sourceId: source.id,
        directory: _.map(source.scanPaths, 'path')
      });

      $scope.mediaIdentList.infiniteOptions.enabled = true;

      return source;
    });
  }

  function fetchMediaDirectory(sourceId, path) {

    var existing = _.find($scope.mediaIdentList.records, { sourceId: sourceId, path: path });
    if (existing) {
      return $q.when(existing);
    }

    return api({
      url: '/media/files',
      params: {
        type: 'directory',
        nfo: 0,
        linked: 0,
        sourceId: sourceId,
        path: path
      }
    }).then(function(res) {
      return _.first(res.data);
    });
  }

  function fetchMediaSource(id) {

    var existing = _.find($scope.mediaSources || [], { id: id });
    if (existing) {
      return $q.when(existing);
    }

    return api({
      url: '/media/sources/' + id,
      params: {
        include: [ 'scanPaths', 'user' ]
      }
    }).then(function(res) {
      addMediaSource(res.data);
      return res.data;
    });
  }

  function fetchMediaSources() {
    return api.all({
      url: '/media/sources',
      params: {
        include: [ 'scanPaths', 'user' ]
      }
    }).then(function(sources) {

      _.each(sources, addMediaSource);

      if (sources.length && !route.source) {
        route.source = (_.find(sources, { id: route.source }) || sources[0]).id;
      }

      return sources;
    });
  }

  function addMediaSource(source) {
    if (!$scope.mediaSources) {
      $scope.mediaSources = [];
    }

    if (!_.find($scope.mediaSources, { id: source.id })) {
      $scope.mediaSources.push(source);
    }
  }
});
