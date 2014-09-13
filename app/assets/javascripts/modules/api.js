angular.module('lair.api', ['lair.auth'])

  .service('ApiService', ['AuthService', '$http', function($auth, $http) {
    return {
      http: function(options) {

        if ($auth.token) {
          if (options.headers === undefined) {
            options.headers = {};
          }

          if (options.headers.Authorization === undefined) {
            options.headers.Authorization = 'Bearer ' + $auth.token;
          }
        }

        return $http(options);
      }
    };
  }])

;
