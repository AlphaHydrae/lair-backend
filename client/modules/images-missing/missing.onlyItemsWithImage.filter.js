angular.module('lair.images.missing').filter('onlyItemsWithImage', function() {
  return function(items, scope) {
    if (scope.showAllItems) {
      return items;
    } else {
      return _.filter(items, function(item) {
        return !item.image || !item.image.id;
      });
    }
  };
});
