angular.module('lair.scrapers').controller('ScraperErrorModalCtrl', function(api, $modalInstance, $scope) {
  api({
    url: '/scraps/' + $scope.scrapId,
    params: {
      include: 'error'
    }
  }).then(function(res) {
    $scope.scrap = res.data;
  });
});
