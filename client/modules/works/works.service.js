angular.module('lair.works').factory('works', function() {

  var commonWrittenWorkRelationTypes = [ 'artist', 'author', 'publishingCompany' ],
      commonVideoRelationTypes = [ 'composer', 'director', 'producer', 'writer', 'productionCompany' ];

  var service = {
    categories: [
      { name: 'anime', relations: commonVideoRelationTypes.concat([ 'voiceActor' ]).sort() },
      { name: 'book', relations: commonWrittenWorkRelationTypes.sort() },
      { name: 'magazine', relations: commonWrittenWorkRelationTypes.sort() },
      { name: 'manga', relations: commonWrittenWorkRelationTypes.sort() },
      { name: 'movie', relations: commonVideoRelationTypes.concat([ 'actor' ]).sort() },
      { name: 'show', relations: commonVideoRelationTypes.concat([ 'actor' ]).sort() }
    ],

    relations: [
      { name: 'actor', resource: 'people' },
      { name: 'artist', resource: 'people' },
      { name: 'author', resource: 'people' },
      { name: 'composer', resource: 'people' },
      { name: 'director', resource: 'people' },
      { name: 'producer', resource: 'people' },
      { name: 'voiceActor', resource: 'people' },
      { name: 'writer', resource: 'people' },
      { name: 'productionCompany', resource: 'companies' },
      { name: 'publishingCompany', resource: 'companies' }
    ],

    relationsForWork: function(work) {
      return _.filter(service.relations, function(relation) {
        var category = _.findWhere(service.categories, { name: work.category });
        return !category || _.includes(category.relations, relation.name);
      });
    },

    relationResource: function(name) {
      var relation = _.findWhere(service.relations, { name: name });
      return relation ? relation.resource : null;
    }
  };

  return service;
});
