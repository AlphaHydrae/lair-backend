angular.module('lair.scraping').controller('ScrapingCtrl', function(api, $location, $scope, scrapers, tables) {

  tables.create($scope, 'mediaUrlsList', {
    url: '/media/urls',
    params: {
      include: 'scrap'
    }
  });

  $scope.showSupportedScrapers = function() {
    scrapers.openSupportModal($scope);
  };

  $scope.showScrapingError = function(scrap) {
    scrapers.openErrorModal($scope, scrap.id);
  };

  $scope.canceledScrapStates = [ 'scrapingCanceled' ];
  $scope.errorScrapStates = [ 'scrapingFailed', 'expansionFailed' ];
  $scope.inProgressScrapStates = [ 'created', 'scraping', 'scraped' ];

  fetchCountByScrapStates('scrapingCanceledCount', $scope.canceledScrapStates);
  fetchCountByScrapStates('scrapingErrorsCount', $scope.errorScrapStates);
  fetchCountByScrapStates('scrapingInProgressCount', $scope.inProgressScrapStates);

  function fetchCountByScrapStates(name, states) {
    api({
      url: '/media/urls',
      params: {
        number: 0,
        scrapStates: states
      }
    }).then(function(res) {
      $scope[name] = res.pagination().total;
    });
  }
});
