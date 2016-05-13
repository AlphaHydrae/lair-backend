angular.module('lair.items').factory('items', function() {

  var service = {
    types: [ 'volume', 'issue', 'video' ],

    typesForWork: function(work) {
      if (_.includes([ 'book', 'manga' ], work.category)) {
        return [ 'volume' ];
      } else if (_.includes([ 'magazine' ], work.category)) {
        return [ 'issue' ];
      } else if (_.includes([ 'anime', 'movie', 'show' ], work.category)) {
        return [ 'video' ];
      }
    }
  };

  return service;
});
