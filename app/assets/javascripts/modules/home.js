angular.module('lair.home', [ 'lair.api', 'lair.collections.preview', 'lair.explorer' ])

  .controller('HomeCtrl', function(api, $modal, $scope, $state) {

    api({
      url: '/collections',
      params: {
        featured: 'daily',
        number: 1
      }
    }).then(function(res) {
      $scope.collections = res.data;
    });
  })

;
