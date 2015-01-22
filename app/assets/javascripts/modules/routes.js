angular.module('lair.routes', [ 'ui.router' ])

  .config(['$stateProvider', function($stateProvider) {

    $stateProvider

      .state('std', {
        abstract: true,
        template: '<div ui-view="navbar" /><div ui-view="content" />'
      })

      .state('std.home', {
        url: '^/',
        views: {
          'navbar@std': {
            templateUrl: '/templates/navbar.html'
          },
          'content@std': {
            templateUrl: '/templates/home.html'
          }
        }
      })

      .state('std.home.item', {
        url: '^/items/:itemId'
      })

      .state('std.items', {
        abstract: true,
        url: '^/items',
        views: {
          'navbar@std': {
            templateUrl: '/templates/navbar.html'
          }
        }
      })

      .state('std.items.edit', {
        url: '/:itemId/edit',
        views: {
          'content@std': {
            templateUrl: '/templates/itemsEdit.html'
          }
        }
      })

    ;

  }])

;
