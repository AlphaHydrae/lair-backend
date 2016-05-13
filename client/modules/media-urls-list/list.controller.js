angular.module('lair.mediaUrls.list').controller('MediaUrlsListCtrl', function(api, $location, newMediaUrlDialog, $scope, scrapers, $stateParams, tables) {

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
    show: $stateParams.show,
    warnings: !!$stateParams.warnings
  };

  $scope.$watch('filters', function(value, oldValue) {
    if (value && value != oldValue) {
      applyFilters();

      var search = $location.search();

      if (value.show != search.show) {
        $location.search('show', value.show);
      }

      if (value.warnings != search.warnings) {
        $location.search('warnings', value.warnings ? 'true' : null);
      }
    }
  }, true);

  $scope.$on('$locationChangeSuccess', function() {

    var search = $location.search(),
        filters = $scope.filters;

    if (search.show != filters.show) {
      filters.show = search.show;
    }

    if (!!search.warnings != filters.warnings) {
      filters.warnings = search.warnings;
    }
  });

  function applyFilters() {

    if ($scope.filters.show) {
      $scope.mediaUrlsList.params.scrapStates = showToStates($scope.filters.show);
    } else {
      delete $scope.mediaUrlsList.params.scrapStates;
    }

    if ($scope.filters.warnings) {
      $scope.mediaUrlsList.params.scrapWarnings = 1;
    } else {
      delete $scope.mediaUrlsList.params.scrapWarnings;
    }
  }

  applyFilters();

  $scope.showSupportedScrapers = function() {
    scrapers.openSupportModal($scope);
  };

  $scope.showScrapingError = function(scrap) {
    scrapers.openErrorModal($scope, scrap.id);
  };

  $scope.openNewMediaUrlDialog = function() {
    newMediaUrlDialog.open($scope);
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
