angular.module('lair.api', ['lair.auth'])

  .service('ApiService', ['$http', function($http) {
    return {
      http: function(options) {
        return $http(options);
      }
    };
  }])

;
