
angular.module('lair.auth.strategy.test', [])

  .factory('TestAuthService', ['$http', function($http) {

    function checkToken(token) {
      return $http({
        method: 'GET',
        url: '/api/auth',
        headers: {
          Authorization: 'Bearer ' + token
        }
      }).then(function(response) {
        return response.data;
      });
    }

    return {
      signIn: checkToken
    };
  }])

;
