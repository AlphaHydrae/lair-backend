
angular.module('lair.auth.google', [])

  .run(['$window', function($window) {
    $window.jQuery.ajax({
      url: 'https://apis.google.com/js/client:plus.js?onload=gpAsyncInit',
      dataType: 'script',
      cache: true
    });
  }])

  .service('GoogleAuthService', ['$q', '$window', '$cookies', 'config.googleOAuth2ClientId', 'config.googleOAuth2CallbackUrl', function($q, $window, $cookies, oauthClientId, oauthCallbackUrl) {

    function redeemGoogleOAuth2Token(gapiResponse) {

      var deferred = $q.defer();

      gapiResponse.state = $cookies['auth.csrfToken'];
      console.log('Redeeming Google OAuth 2 token (CSRF token: ' + gapiResponse.state + ')');

      $window.jQuery.ajax({
        type: 'POST',
        url: oauthCallbackUrl,
        dataType: 'json',
        data: gapiResponse,
        success: function(authPayload) {
          deferred.resolve(authPayload);
        }, error: function(err) {
          deferred.reject(err);
        }
      });

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

    function signInWithGoogle() {

      var deferred = $q.defer();

      console.log('Authenticating to Google (CSRF token: ' + $cookies['auth.csrfToken'] + ')');

      $window.gapi.auth.authorize({
        immediate: false,
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
      signIn: signInWithGoogle
    };
  }]);
