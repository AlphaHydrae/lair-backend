angular.module('lair.mediaIdent').controller('MediaIdentCtrl', function(api, auth, $location, mediaIdentDialog, $scope, $stateParams, tables) {

  $scope.mediaIdentList = {
    records: [],
    httpSettings: {
      url: '/media/files',
      params: {
        type: 'directory',
        nfo: 0,
        linked: 0
      }
    },
    infiniteOptions: {
      enabled: false
    }
  };

  fetchMediaSources();

  $scope.$watch('mediaIdentList.mediaSource', onMediaSourceSelected);

  $scope.identifyMedia = function(directory) {
    mediaIdentDialog.open($scope, {
      mediaDirectory: directory
    });
  };

  function onMediaSourceSelected(source) {
    if (!source) {
      return;
    }

    $location.search('source', source.id);

    var params = $scope.mediaIdentList.httpSettings.params;
    _.extend(params, {
      sourceId: source.id,
      directory: _.map(source.scanPaths, 'path')
    });

    $scope.mediaIdentList.infiniteOptions.enabled = true;
  }

  function fetchMediaSources() {

    var params = {
      include: [ 'scanPaths', 'user' ]
    };

    if (!auth.currentUserIs('admin')) {
      params.userId = auth.currentUser.id;
    }

    api.all({
      url: '/media/sources',
      params: params
    }).then(function(sources) {
      $scope.mediaSources = sources;
      if (sources.length && !$scope.mediaIdentList.mediaSource) {
        $scope.mediaIdentList.mediaSource = _.find(sources, { id: $stateParams.source }) || sources[0];
      }
    });
  }
});
