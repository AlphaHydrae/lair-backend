angular.module('lair.mediaUrls.new').factory('newMediaUrlDialog', function($uibModal) {

  var service = {
    open: function($scope) {

      var modal = $uibModal.open({
        scope: $scope,
        controller: 'NewMediaUrlDialogCtrl',
        templateUrl: '/templates/modules/media-urls-new/new.dialog.template.html'
      });

      return modal.result;
    }
  };

  return service;

}).controller('NewMediaUrlDialogCtrl', function(api, busy, $uibModalInstance, scrapers, $scope) {

  $scope.mediaUrl = {};

  $scope.$watch('mediaUrl.url', function(value, oldValue) {
    if (value !== oldValue && $scope.resolvedMediaUrl) {
      delete $scope.resolvedMediaUrl;
    }
  });

  $scope.showSupportedScrapers = function() {
    scrapers.openSupportModal($scope);
  };

  $scope.resolve = function() {

    busy($scope, true);

    api({
      method: 'POST',
      url: '/media/urlResolution',
      data: $scope.mediaUrl
    }).then(function(res) {
      $scope.resolvedMediaUrl = res.data;
    }).finally(_.partial(busy, $scope, false));
  };

  $scope.scrap = function() {

    busy($scope, true);

    api({
      method: 'POST',
      url: '/media/urls',
      data: $scope.resolvedMediaUrl
    }).then(function(res) {
      $uibModalInstance.close(res.data);
    }).finally(_.partial(busy, $scope, false));
  };
});
