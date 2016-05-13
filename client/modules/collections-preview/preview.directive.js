angular.module('lair.collections.preview').directive('collectionPreview', function() {
  return {
    restrict: 'E',
    templateUrl: '/templates/modules/collections-preview/preview.template.html',
    controller: 'CollectionPreviewCtrl',
    scope: {
      collection: '=',
      autoUpdate: '='
    },
    link: function($scope, element) {

      var e = $(element);
      $scope.countVisibleElements = function() {
        return e.find('.elements .element:visible').length;
      };
    }
  };
});
