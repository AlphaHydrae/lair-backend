angular.module('lair.home').controller('HomeCtrl', function(api, explorer, $scope, $state) {

  explorer.openFromLocation($scope);

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
