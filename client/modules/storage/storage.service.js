angular.module('lair.storage').factory('appStore', function(store) {
  return store.getNamespacedStore('lair');
});
