
angular.module('lair.auth.strategy.google', [])

  .run(['$window', function($window) {
    $window.jQuery.ajax({
      url: 'https://apis.google.com/js/client:plus.js?onload=gpAsyncInit',
      dataType: 'script',
      cache: true
    });
  }])

  .factory('GoogleAuthService', ['config.googleOAuth2ClientId', 'config.googleOAuth2CallbackUrl', '$cookies', '$log', '$q', '$window', function(oauthClientId, oauthCallbackUrl, $cookies, $log, $q, $window) {

    function redeemGoogleOAuth2Token(gapiResponse) {

      var deferred = $q.defer();

      gapiResponse.state = $cookies['auth.csrfToken'];
      $log.debug('Redeeming Google OAuth 2 token (CSRF token: ' + gapiResponse.state + ')');

      $window.jQuery.ajax({
        type: 'POST',
        url: oauthCallbackUrl,
        dataType: 'json',
        data: gapiResponse
      }).done(deferred.resolve).fail(deferred.reject);

      // FIXME: replace $.ajax by $http
      /*return $http({
        method: 'POST',
        url: 'http://localhost:3000/users/auth/google_oauth2/callback',
        data: $.param(gapiResponse),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });*/

      return deferred.promise;
    }

    function signInWithGoogle(immediate) {

      var deferred = $q.defer();

      $log.debug('Authenticating with Google OAuth 2 (CSRF token: ' + $cookies['auth.csrfToken'] + ')');

      $window.gapi.auth.authorize({
        immediate: immediate,
        response_type: 'code',
        cookie_policy: 'single_host_origin',
        client_id: oauthClientId,
        scope: 'email',
        state: $cookies['auth.csrfToken']
      }, function(gapiResponse) {
        if (gapiResponse && !gapiResponse.error) {
          deferred.resolve(redeemGoogleOAuth2Token(gapiResponse));
        } else {
          deferred.reject(gapiResponse ? gapiResponse.error : undefined);
        }
      });

      return deferred.promise;
    }

    return {
      checkSignedIn: _.bind(signInWithGoogle, undefined, true),
      signIn: _.bind(signInWithGoogle, undefined, false)
    };
  }])

;
