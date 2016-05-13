angular.module('lair.routes', [ 'ui.router' ])

  .config(function($stateProvider) {

    $stateProvider

      .state('home', {
        url: '^/',
        templateUrl: '/templates/home.html',
        controller: 'HomeCtrl'
      })

      .state('profile', {
        url: '^/profile',
        templateUrl: '/templates/profile.html',
        controller: 'ProfileCtrl'
      })

      .state('items', {
        abstract: true,
        url: '^/items',
        template: '<div ui-view />'
      })

      .state('items.list', {
        url: '^/items',
        templateUrl: '/templates/items-list.html',
        controller: 'ItemsListCtrl'
      })

      .state('items.create', {
        url: '^/items/new',
        templateUrl: '/templates/createItem.html'
      })

      .state('items.edit', {
        url: '/:itemId/edit',
        templateUrl: '/templates/editItem.html'
      })

      .state('parts', {
        abstract: true,
        url: '^/parts',
        template: '<div ui-view />'
      })

      .state('parts.create', {
        url: '^/parts/new?itemId',
        templateUrl: '/templates/createPart.html'
      })

      .state('parts.edit', {
        url: '/:partId/edit',
        templateUrl: '/templates/editPart.html'
      })

      .state('collections', {
        abstract: true,
        url: '^/collections',
        template: '<div ui-view />'
      })

      .state('collections.list', {
        url: '^/collections',
        templateUrl: '/templates/collections-list.html',
        controller: 'CollectionsListCtrl'
      })

      .state('collections.edit', {
        url: '/:id/edit',
        templateUrl: '/templates/collections-edit.html',
        controller: 'EditCollectionCtrl'
      })

      .state('ownerships', {
        abstract: true,
        url: '^/ownerships',
        template: '<div ui-view />'
      })

      .state('ownerships.list', {
        url: '^/ownerships',
        templateUrl: '/templates/listOwnerships.html'
      })

      .state('images', {
        abstract: true,
        url: '^/images',
        template: '<div ui-view />'
      })

      .state('images.missing', {
        url: '/missing',
        templateUrl: '/templates/setMissingImages.html'
      })

      .state('events', {
        abstract: true,
        url: '^/events',
        template: '<div ui-view />'
      })

      .state('events.list', {
        url: '^/events',
        templateUrl: '/templates/listEvents.html'
      })

      .state('status', {
        url: '^/status',
        templateUrl: '/templates/status.html',
        controller: 'StatusCtrl'
      })

      .state('users', {
        abstract: true,
        url: '^/users',
        template: '<div ui-view />'
      })

      .state('users.list', {
        url: '^/users',
        templateUrl: '/templates/users-list.html',
        controller: 'UsersListCtrl'
      })

      .state('users.new', {
        url: '/new',
        templateUrl: '/templates/users-new.html',
        controller: 'NewUserCtrl'
      })

      .state('users.edit', {
        url: '/:id',
        templateUrl: '/templates/users-edit.html',
        controller: 'EditUserCtrl'
      })

      .state('collection', {
        url: '^/:userName/:collectionName',
        templateUrl: '/templates/collections-show.html',
        controller: 'CollectionCtrl'
      })

    ;

  })

;
