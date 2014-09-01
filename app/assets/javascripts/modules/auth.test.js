
angular.module('lair.auth.test', [])

  .service('TestAuthService', ['$http', function($http) {

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
  }]);
