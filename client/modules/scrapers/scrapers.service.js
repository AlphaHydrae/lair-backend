angular.module('lair.scrapers').factory('scrapers', function($modal) {

  var service = {
    openErrorModal: function($scope, scrapId) {

      var scope = $scope.$new();
      scope.scrapId = scrapId;

      var modal = $modal.open({
        size: 'lg',
        scope: scope,
        controller: 'ScraperErrorModalCtrl',
        templateUrl: '/templates/modules/scrapers/scrapers.error.template.html'
      });

      return modal.result;
    },

    openSupportModal: function($scope) {

      var modal = $modal.open({
        size: 'lg',
        scope: $scope,
        templateUrl: '/templates/modules/scrapers/scrapers.supported.template.html'
      })

      return modal.result;
    }
  };

  return service;
});
