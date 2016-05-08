angular.module('lair.files.explorer').controller('FileExplorerCtrl', function(api, auth, $location, $scope, $stateParams) {

  $scope.mediaFilesList = {
    records: [],
    httpSettings: {
      url: '/media/files',
      params: {
        include: [ 'filesCount', 'linkedFilesCount', 'mediaUrl' ]
      }
    },
    infiniteOptions: {
      enabled: false
    }
  };

  $scope.$watch('mediaSource', function(value, oldValue) {
    if (value) {

      var directory;
      if (oldValue && value != oldValue) {
        directory = '/';
      } else {
        directory = $stateParams.directory || '/';
      }

      var params = $scope.mediaFilesList.httpSettings.params;
      _.extend(params, {
        directory: directory,
        deleted: $stateParams.deleted || 0,
        maxDepth: 1,
        sourceId: value.id
      });

      resetBreadcrumbs();

      $scope.mediaFilesList.infiniteOptions.enabled = true;

      fetchFilesCount();
    }
  });

  $scope.$on('$locationChangeSuccess', function() {

    var search = $location.search(),
        params = $scope.mediaFilesList.httpSettings.params;

    if ((search.directory || '/') != params.directory) {
      params.directory = search.directory || '/';
      resetBreadcrumbs();
    }

    if ((search.deleted || 0) != params.deleted) {
      params.deleted = search.deleted;
    }
  });

  $scope.$watch('mediaFilesList.httpSettings.params.directory', function(directory) {
    $location.search('directory', directory && directory != '/' ? directory : null);
  });

  $scope.$watch('mediaFilesList.httpSettings.params.deleted', function(deleted) {
    $location.search('deleted', deleted ? deleted : null);
  });

  api.all({
    url: '/media/sources',
    params: {
      userId: auth.currentUser.id,
      withScanPaths: 1
    }
  }).then(function(sources) {
    $scope.mediaSources = sources;
    if (sources.length) {
      $scope.mediaSource = sources[0];
    }
  });

  $scope.breadcrumbs = [];

  $scope.open = function(path) {

    var params = $scope.mediaFilesList.httpSettings.params,
        currentDirectory = params.directory;

    params.directory = path;

    var index = _.indexOf($scope.breadcrumbs, path);
    if (index >= 0) {
      $scope.breadcrumbs.splice(index + 1, $scope.breadcrumbs.length - index - 1);
    } else if (path.indexOf(params.currentDirectory + '/') === 0) {
      $scope.breadcrumbs.push(path);
    } else {
      resetBreadcrumbs();
    }
  };

  $scope.openRoot = function() {
    $scope.breadcrumbs.length = 0;
    $scope.mediaFilesList.httpSettings.params.directory = '/';
  };

  $scope.getFilesState = function() {
    if (!$scope.mediaFilesList.records.length) {
      return;
    }

    var states = _.reduce($scope.mediaFilesList.records, function(memo, file) {
      if (!file.deleted && file.type == 'file' && file.extension != 'nfo' && !_.includes(memo, file.state)) {
        memo.push(file.state);
      }

      return memo;
    }, []);

    if (!states.length) {
      return 'none';
    }

    return _.find([ 'unlinked', 'created', 'linked' ], function(state) {
      return _.includes(states, state);
    }) || 'none';
  }

  $scope.getNfoState = function() {
    if (!$scope.mediaFilesList.records.length) {
      return;
    }

    var states = _.reduce($scope.mediaFilesList.records, function(memo, file) {
      if (!file.deleted && file.type == 'file' && file.extension == 'nfo' && !_.includes(memo, file.state)) {
        memo.push(file.state);
      }

      return memo;
    }, []);

    if (!states.length) {
      return 'none';
    }

    return _.find([ 'duplicated', 'invalid', 'changed', 'unlinked', 'linked' ], function(state) {
      return _.includes(states, state);
    }) || 'none';
  }

  $scope.enrichMediaFiles = function(res) {
    _.each(res.data, function(file) {
      if (file.deleted) {
        file.error = 'fileDeleted';
      } else if (nfoIs(file, 'duplicated')) {
        file.error = 'nfoDuplicated';
      } else if (nfoIs(file, 'invalid')) {
        file.error = 'nfoInvalid';
      } else if (directoryHasUnlikedFiles(file)) {
        file.warning = 'directoryHasUnlikedFiles';
      } else if (fileIsUnlinked(file)) {
        file.warning = 'fileUnlinked';
      }
    });
  };

  function nfoIs(file, state) {
    return !file.deleted && file.type == 'file' && file.extension == 'nfo' && file.state == state;
  }

  function directoryHasUnlikedFiles(file) {
    return !file.deleted && file.type == 'directory' && file.linkedFilesCount < file.filesCount;
  }

  function fileIsUnlinked(file) {
    return !file.deleted && file.type == 'file' && file.extension != 'nfo' && file.state != 'linked';
  };

  function resetBreadcrumbs() {

    $scope.breadcrumbs.length = 0;

    var directory = $scope.mediaFilesList.httpSettings.params.directory || '/';

    if (directory == '/') {
      return;
    }

    var previousDirectory = directory,
        completed = false,
        currentDirectory;

    while (!completed) {
      currentDirectory = previousDirectory.replace(/\/[^\/]+$/, '');
      if (currentDirectory != previousDirectory) {
        $scope.breadcrumbs.unshift(previousDirectory);
        previousDirectory = currentDirectory;
      } else {
        completed = true;
      }
    };
  }

  function fetchFilesCount() {
    api({
      url: '/media/files',
      params: {
        type: 'file',
        number: 0
      }
    }).then(function(res) {
      $scope.sourceFilesCount = res.pagination().filteredTotal;
    });
  }
});
