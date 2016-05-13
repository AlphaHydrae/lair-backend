angular.module('lair.storage', [ 'angular-storage' ])

  .factory('appStore', function(store) {
    return store.getNamespacedStore('lair');
  })

;
