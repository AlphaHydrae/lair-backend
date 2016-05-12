angular.module('lair').factory('languages', function(api, $log, $q) {

  var languages,
      loading = false,
      deferreds = [];

  var service = {
    loadLanguages: function() {
      if (languages) {
        return $q.when(languages);
      }

      var deferred = $q.defer()
      deferreds.push(deferred);

      api({
        url: '/languages'
      }).then(function(res) {

        languages = res.data;

        _.invoke(deferreds, 'resolve', languages);
        delete deferreds;
      }).catch(function(err) {
        $log.warn('Could not load languages');
        $log.debug(err);
      });

      return deferred.promise;
    },

    addLanguages: function($scope) {
      service.loadLanguages().then(function(languages) {
        $scope.languages = languages;
      });
    }
  };

  return service;
});
