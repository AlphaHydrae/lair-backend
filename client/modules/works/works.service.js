angular.module('lair.works').factory('works', function(api, $q) {

  var personRelations,
      companyRelations;

  var service = {
    categories: [
      { name: 'anime' },
      { name: 'book' },
      { name: 'magazine' },
      { name: 'manga' },
      { name: 'movie' },
      { name: 'show' }
    ],

    loadPersonRelations: function() {
      if (personRelations) {
        return $q.when(personRelations);
      }

      return api.all({
        url: '/personRelations'
      }).then(function(relations) {
        personRelations = relations;
        return personRelations;
      });
    },

    loadCompanyRelations: function() {
      if (companyRelations) {
        return $q.when(companyRelations);
      }

      return api.all({
        url: '/companyRelations'
      }).then(function(relations) {
        companyRelations = relations;
        return companyRelations;
      });
    }
  };

  return service;
});
