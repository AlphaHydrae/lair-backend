angular.module('lair.scraping').controller('ScrapingCtrl', function(api, $location, $scope, scrapers, $stateParams, tables) {

  var canceledScrapStates = [ 'scrapingCanceled' ],
      errorScrapStates = [ 'scrapingFailed', 'expansionFailed' ],
      inProgressScrapStates = [ 'created', 'scraping', 'scraped', 'expanding' ];

  tables.create($scope, 'mediaUrlsList', {
    url: '/media/urls',
    params: {
      include: [ 'scrap', 'work' ]
    }
  });

  $scope.filters = {
    show: $stateParams.show
  };

  $scope.$watch('filters', function(value, oldValue) {
    if (value && value != oldValue) {
      applyFilters();

      var search = $location.search();

      if (value.show != search.show) {
        $location.search('show', value.show);
      }
    }
  }, true);

  $scope.$on('$locationChangeSuccess', function() {

    var search = $location.search(),
        filters = $scope.filters;

    if (search.show != filters.show) {
      filters.show = search.show;
    }
  });

  function applyFilters() {
    if ($scope.filters.show) {
      $scope.mediaUrlsList.params.scrapStates = showToStates($scope.filters.show);
    } else {
      delete $scope.mediaUrlsList.params.scrapStates;
    }
  }

  applyFilters();

  $scope.showSupportedScrapers = function() {
    scrapers.openSupportModal($scope);
  };

  $scope.showScrapingError = function(scrap) {
    scrapers.openErrorModal($scope, scrap.id);
  };

  function showToStates(show) {
    switch (show) {
      case 'errors':
        return errorScrapStates;
      case 'canceled':
        return canceledScrapStates;
      case 'inProgress':
        return inProgressScrapStates;
    }
  }

  fetchCountByScrapStates('scrapingCanceledCount', canceledScrapStates);
  fetchCountByScrapStates('scrapingErrorsCount', errorScrapStates);
  fetchCountByScrapStates('scrapingInProgressCount', inProgressScrapStates);

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
