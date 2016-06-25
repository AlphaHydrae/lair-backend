angular.module('lair.mediaIdent.dialog').controller('MediaIdentDialogCtrl', function(api, $scope) {

  fetchExistingSearch().then(function(search) {
    return search || performSearch();
  }).then(function(search) {
    $scope.search = search;
  });

  function fetchExistingSearch() {
    return api({
      url: '/media/searches',
      params: {
        number: 1,
        include: 'results',
        query: $scope.mediaDirectory.path.replace(/^.+\//, '')
      }
    }).then(function(res) {
      return _.first(res.data);
    });
  }

  function performSearch() {
    return api({
      method: 'POST',
      url: '/media/searches',
      data: {
        sourceId: $scope.mediaDirectory.sourceId,
        directory: $scope.mediaDirectory.path
      },
      params: {
        include: 'results'
      }
    }).then(function(res) {
      return res.data;
    });
  }
});
