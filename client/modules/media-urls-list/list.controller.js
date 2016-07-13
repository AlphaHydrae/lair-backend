angular.module('lair.mediaUrls.list').controller('MediaUrlsListCtrl', function(api, $location, mediaUrls, newMediaUrlDialog, $scope, scrapers, $stateParams, tables) {

  var errorScrapStates = [ 'scrapingFailed', 'expansionFailed' ],
      inProgressScrapStates = [ 'created', 'scraping', 'scraped', 'expanding' ];

  tables.create($scope, 'mediaUrlsList', {
    url: '/media/urls',
    params: {
      include: [ 'scrap', 'work' ]
    }
  });

  $scope.filters = {
    show: $stateParams.show,
    warnings: !!$stateParams.warnings,
    provider: $stateParams.provider,
    providerId: $stateParams.providerId,
    search: $stateParams.search
  };

  mediaUrls.loadProviders().then(function(providers) {
    $scope.providers = providers;
  });

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

      _.each([ 'provider', 'providerId', 'search' ], function(param) {
        if (value[param] != search[param]) {
          $location.search(param, value[param] ? value[param] : null);
        }
      });
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

    _.each([ 'provider', 'providerId', 'search' ], function(param) {
      if (search[param] != filters[param]) {
        filters[param] = search[param];
      }
    });
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

    _.each([ 'provider', 'providerId', 'search' ], function(param) {
      if ($scope.filters[param]) {
        $scope.mediaUrlsList.params[param] = $scope.filters[param];
      } else {
        delete $scope.mediaUrlsList.params[param];
      }
    });
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

  $scope.retryMatching = function() {
    if (!confirm('Are you sure you want to retry ' + $scope.mediaUrlsList.pagination.total + ' media items?')) {
      return;
    }

    var params = {};
    if ($scope.filters.show) {
      params.states = showToStates($scope.filters.show);
    }

    if ($scope.filters.warnings) {
      params.warnings = 1;
    }

    api({
      method: 'POST',
      url: '/media/scraps/retry',
      params: params
    }).then(function() {
      $scope.retrying = true;
    });
  };

  function showToStates(show) {
    switch (show) {
      case 'errors':
        return errorScrapStates;
      case 'inProgress':
        return inProgressScrapStates;
    }
  }

  fetchWarningsCount();
  fetchCountByScrapStates('scrapingErrorsCount', errorScrapStates);
  fetchCountByScrapStates('scrapingInProgressCount', inProgressScrapStates);

  function fetchWarningsCount() {
    api({
      url: '/media/urls',
      params: {
        number: 0,
        scrapWarnings: 1
      }
    }).then(function(res) {
      $scope.scrapingWarningsCount = res.pagination().total;
    });
  }

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
