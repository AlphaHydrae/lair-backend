angular.module('lair.collections.edit').directive('editCollectionLinks', function() {
  return {
    restrict: 'E',
    templateUrl: '/templates/modules/collections-edit/edit.links.template.html',
    controller: 'EditCollectionLinksCtrl',
    scope: {
      collection: '=',
      enabled: '='
    }
  };
});
