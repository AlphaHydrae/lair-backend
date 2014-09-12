
angular.module('lair.auth.strategy', ['lair.auth.strategy.google', 'lair.auth.strategy.test'])

  .factory('AuthStrategiesService', ['GoogleAuthService', '$log', '$q', 'TestAuthService', function($googleAuth, $log, $q, $testAuth) {

    var service = {};

    var strategies = {
      google: $googleAuth,
      test: $testAuth
    };

    function getStrategy(name) {
      if (!strategies[name]) {
        // TODO: why does throw not work here?
        return $q.reject(new Error('Unknown authentication strategy ' + name));
      }

      return strategies[name];
    }

    function notSignedIn(err) {
      $log.debug('User is not signed in');
      return $q.reject(err);
    }

    return {
      checkSignedIn: function(options) {

        $log.debug('Checking if user is already signed in with ' + options.strategyName + ' strategy');

        return $q.when(options.strategyName).then(getStrategy).then(function(strategy) {
          return strategy.checkSignedIn ? strategy.checkSignedIn().then(undefined, notSignedIn) : notSignedIn();
        }, notSignedIn);
      },

      signIn: function(options) {
        return $q.when(options.strategyName).then(getStrategy).then(function(strategy) {
          return strategy.signIn(options.credentials);
        });
      }
    };
  }])

;
