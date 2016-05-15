angular.module('lair').factory('languages', function(api, $log, $q) {

  var languages,
      languagesByTag,
      loading = false,
      deferreds = [];

  var service = {
    loadLanguages: function() {
      if (languages) {
        return $q.when(languages);
      }

      var deferred = $q.defer()
      deferreds.push(deferred);

      if (!loading) {
        loading = true;

        api({
          url: '/languages'
        }).then(function(res) {

          languages = res.data;
          _.each(deferreds, function(deferred) {
            deferred.resolve(languages);
          });

          delete deferreds;
        }).catch(function(err) {
          $log.warn('Could not load languages');
          $log.debug(err);
        });
      }

      return deferred.promise;
    },

    loadLanguageNamesByTag: function() {
      if (languagesByTag) {
        return $q.when(languagesByTag);
      }

      return service.loadLanguages().then(function(languages) {

        languagesByTag = _.reduce(languages, function(memo, language) {
          memo[language.tag] = language.name;
          return memo;
        }, {});

        return languagesByTag;
      });
    },

    addLanguages: function($scope) {
      return service.loadLanguages().then(function(languages) {
        $scope.languages = languages;
      });
    }
  };

  return service;
});
