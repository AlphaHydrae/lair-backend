angular.module('lair.files.explorer').controller('FileExplorerCtrl', function(api, auth, $location, $scope, scrapers, $stateParams) {

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

  $scope.$watch('mediaFilesList.mediaSource', function(value, oldValue) {
    if (value) {

      $location.search('source', value.id);

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

  // TODO: add text search
  $scope.$on('$locationChangeSuccess', function() {

    var search = $location.search(),
        params = $scope.mediaFilesList.httpSettings.params;

    if (search.source != params.sourceId) {
      var mediaSource = _.find($scope.mediaSources, { id: search.source });
      if (mediaSource) {
        $scope.mediaFilesList.mediaSource = mediaSource;
      }
    }

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
    if (sources.length && !$scope.mediaFilesList.mediaSource) {
      $scope.mediaFilesList.mediaSource = _.find(sources, { id: $stateParams.source }) || sources[0];
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

  $scope.showSupportedScrapers = function() {
    scrapers.openSupportModal();
  };

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
      } else if (fileIsBeingProcessed(file)) {
        file.processing = true;
      }
    });
  };

  $scope.$watch('mediaFilesList.records', function(records) {
    if (records) {

      delete $scope.directoryMessage;
      delete $scope.directoryMessageType;
      delete $scope.nfoFile;
      delete $scope.duplicatedNfoCount;

      var nfoFile = _.find(records, { type: 'file', deleted: false, extension: 'nfo' }),
          duplicatedNfoCount = _.filter(records, { error: 'nfoDuplicated' }).length;

      if (duplicatedNfoCount) {
        $scope.directoryMessageType = 'error';
        $scope.directoryMessage = 'nfoDuplicated';
        $scope.duplicatedNfoCount = duplicatedNfoCount;
      } else if (nfoFile && nfoFile.error == 'nfoInvalid') {
        $scope.directoryMessageType = 'error';
        $scope.directoryMessage = 'nfoInvalid';
        $scope.nfoFile = nfoFile;
      } else if (_.find(records, { warning: 'fileUnlinked' })) {
        $scope.directoryMessageType = 'warning';
        $scope.directoryMessage = 'unlinkedFiles';
      } else if (_.find(records, { warning: 'directoryHasUnlikedFiles' })) {
        $scope.directoryMessageType = 'warning';
        $scope.directoryMessage = 'unlinkedWarnings';
      } else if (_.find(records, { processing: true })) {
        $scope.directoryMessageType = 'info';
        $scope.directoryMessage = 'filesProcessing';
      }
    }
  }, true);

  function nfoIs(file, state) {
    return !file.deleted && file.type == 'file' && file.extension == 'nfo' && file.state == state;
  }

  function directoryHasUnlikedFiles(file) {
    return !file.deleted && file.type == 'directory' && file.linkedFilesCount < file.filesCount;
  }

  function fileIsUnlinked(file) {
    return !file.deleted && file.type == 'file' && file.extension != 'nfo' && file.state != 'linked';
  }

  function fileIsBeingProcessed(file) {
    return !file.deleted && file.type == 'file' && file.state == 'created';
  }

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
