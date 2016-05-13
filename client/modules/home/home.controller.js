angular.module('lair.home').controller('HomeCtrl', function(api, $modal, $scope, $state) {
  api({
    url: '/collections',
    params: {
      featured: 'daily',
      number: 1,
      withUser: 1
    }
  }).then(function(res) {
    $scope.collections = res.data;
  });
});
