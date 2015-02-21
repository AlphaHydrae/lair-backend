angular.module('lair.auth.token', ['satellizer'])

  .factory('TokenAuthService', ['$auth', '$http', function($auth, $http) {

    function checkToken(token) {
      return $http({
        method: 'POST',
        url: '/auth/token',
        headers: {
          Authorization: 'Bearer ' + token
        }
      }).then(function(response) {
        $auth.setToken(response.data.token);
        return response;
      });
    }

    return {
      authenticate: checkToken
    };
  }])

;
