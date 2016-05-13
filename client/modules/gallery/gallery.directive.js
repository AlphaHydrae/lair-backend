angular.module('lair.gallery').directive('gallery', function() {
  return {
    restrict: 'E',
    controller: 'GalleryCtrl',
    templateUrl: '/templates/modules/gallery/gallery.template.html',
    scope: {
      records: '=',
      collection: '=',
      collectionModified: '=',
      displayEnabled: '=',
      displayType: '=',
      onSelect: '&',
      selected: '&'
    }
  };
});
