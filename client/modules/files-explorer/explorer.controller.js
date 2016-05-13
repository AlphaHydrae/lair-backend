angular.module('lair.files.explorer').controller('FileExplorerCtrl', function(api, auth, $scope) {

  $scope.mediaFilesList = {
    records: [],
    httpSettings: {
      url: '/api/media/files',
      params: {}
    },
    infiniteOptions: {
      enabled: false
    }
  };

  $scope.$watch('mediaSource', function(value) {
    if (value) {
      $scope.mediaFilesList.httpSettings.params.directory = '/';
      $scope.mediaFilesList.httpSettings.params.maxDepth = 1;
      $scope.mediaFilesList.httpSettings.params.sourceId = value.id;
      $scope.mediaFilesList.infiniteOptions.enabled = true;
      fetchFilesCount();
    }
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

  $scope.open = function(file) {

    var index = _.indexOf($scope.breadcrumbs, file);
    if (index >= 0) {
      $scope.breadcrumbs.splice(index + 1, $scope.breadcrumbs.length - index - 1);
    } else {
      $scope.breadcrumbs.push(file);
    }

    $scope.mediaFilesList.httpSettings.params.directory = file.path;
  };

  $scope.openScanPath = function(path) {

    var alreadyOpenedDirectory = _.findWhere($scope.breadcrumbs, { path: path });
    if (alreadyOpenedDirectory) {
      return $scope.open(alreadyOpenedDirectory);
    }

    fetchScanPathFiles(path).then(function(files) {
      $scope.breadcrumbs = files;
      $scope.mediaFilesList.httpSettings.params.directory = path;
    });
  };

  $scope.openRoot = function() {
    $scope.breadcrumbs.length = 0;
    $scope.mediaFilesList.httpSettings.params.directory = '/';
  };

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

  function fetchScanPathFiles(path, files) {
    files = files || [];

    return api({
      url: '/media/files',
      params: {
        path: path,
        sourceId: $scope.mediaSource.id,
        number: 1
      }
    }).then(function(res) {
      files.unshift(res.data[0]);

      if (path.match(/(?:\/[^\/]+){2,}$/)) {
        return fetchScanPathFiles(path.replace(/\/[^\/]+$/, ''), files);
      } else {
        return files;
      }
    });
  }
});
