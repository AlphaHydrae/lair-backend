angular.module('lair.mediaUrls').factory('mediaUrls', function($q) {

  var providers = [
    {
      name: 'anidb'
    },
    {
      name: 'imdb'
    }
  ];

  var service = {
    loadProviders: function() {
      return $q.when(providers);
    }
  };

  return service;
});
