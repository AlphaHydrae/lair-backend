
angular.module('lair.state', [ 'ui.router' ])

  .config(['$stateProvider', '$locationProvider', '$urlRouterProvider', function($stateProvider, $locationProvider, $urlRouterProvider) {

    $locationProvider.html5Mode(true);
    $urlRouterProvider.otherwise("/");

    $stateProvider
      .state('home', {
        url: "/",
        templateUrl: "templates/home.html"
      });
  }])

;
