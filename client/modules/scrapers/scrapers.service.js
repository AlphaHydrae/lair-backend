angular.module('lair.scrapers').factory('scrapers', function($modal) {

  var service = {
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
