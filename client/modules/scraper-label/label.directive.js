angular.module('lair.scrapers.label').directive('scraperLabel', function() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      scraper: '@'
    },
    controller: 'ScraperLabelCtrl',
    templateUrl: '/templates/modules/scraper-label/label.template.html'
  };
}).controller('ScraperLabelCtrl', function($scope) {
  if ($scope.scraper == 'anidb') {
    $scope.name = 'AniDB';
    $scope.url = 'http://anidb.net';
  } else if ($scope.scraper == 'imdb') {
    $scope.name = 'IMDB';
    $scope.url = 'http://www.imdb.com';
  }
});
