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

      .state('std.items.create', {
        url: '^/items/new',
        views: {
          'content@std': {
            templateUrl: '/templates/createItem.html'
          }
        }
      })

      .state('std.items.edit', {
        url: '/:itemId/edit',
        views: {
          'content@std': {
            templateUrl: '/templates/editItem.html'
          }
        }
      })

      .state('std.parts', {
        abstract: true,
        url: '^/parts',
        views: {
          'navbar@std': {
            templateUrl: '/templates/navbar.html'
          }
        }
      })

      .state('std.parts.create', {
        url: '^/parts/new?itemId',
        views: {
          'content@std': {
            templateUrl: '/templates/createPart.html'
          }
        }
      })

      .state('std.parts.edit', {
        url: '/:partId/edit',
        views: {
          'content@std': {
            templateUrl: '/templates/editPart.html'
          }
        }
      })

      .state('std.images', {
        abstract: true,
        url: '^/images',
        views: {
          'navbar@std': {
            templateUrl: '/templates/navbar.html'
          }
        }
      })

      .state('std.images.missing', {
        url: '/missing',
        views: {
          'content@std': {
            templateUrl: '/templates/setMissingImages.html'
          }
        }
      })
    ;

  }])
;
