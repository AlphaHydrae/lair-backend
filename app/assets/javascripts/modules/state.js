angular.module('lair.state', [ 'ui.router' ])

  .config(function($locationProvider, $urlRouterProvider) {
    $locationProvider.html5Mode(true);
    $urlRouterProvider.otherwise("/");
  })

;
