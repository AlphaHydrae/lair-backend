angular.module('lair.routes', [ 'ui.router' ])

  .config(function($stateProvider) {

    $stateProvider

      .state('home', {
        url: '^/',
        controller: 'HomeCtrl',
        templateUrl: '/templates/modules/home/home.template.html'
      })

      .state('profile', {
        url: '^/profile',
        controller: 'ProfileCtrl',
        templateUrl: '/templates/modules/profile/profile.template.html'
      })

      .state('works', {
        abstract: true,
        url: '^/works',
        template: '<div ui-view />'
      })

      .state('works.list', {
        url: '^/works',
        controller: 'WorksListCtrl',
        templateUrl: '/templates/modules/works-list/list.template.html'
      })

      .state('works.new', {
        url: '^/works/new',
        controller: 'NewWorkCtrl',
        templateUrl: '/templates/modules/works-new/new.template.html'
      })

      .state('works.edit', {
        url: '/:workId/edit',
        controller: 'EditWorkCtrl',
        templateUrl: '/templates/modules/works-edit/edit.template.html'
      })

      .state('items', {
        abstract: true,
        url: '^/items',
        template: '<div ui-view />'
      })

      .state('items.new', {
        url: '^/items/new?workId',
        controller: 'NewItemCtrl',
        templateUrl: '/templates/modules/items-new/new.template.html'
      })

      .state('items.edit', {
        url: '/:itemId/edit',
        controller: 'EditItemCtrl',
        templateUrl: '/templates/modules/items-edit/edit.template.html'
      })

      .state('collections', {
        abstract: true,
        url: '^/collections',
        template: '<div ui-view />'
      })

      .state('collections.list', {
        url: '^/collections',
        controller: 'CollectionsListCtrl',
        templateUrl: '/templates/modules/collections-list/list.template.html'
      })

      .state('collections.edit', {
        url: '/:id/edit',
        controller: 'EditCollectionCtrl',
        templateUrl: '/templates/modules/collections-edit/edit.template.html'
      })

      .state('ownerships', {
        abstract: true,
        url: '^/ownerships',
        template: '<div ui-view />'
      })

      .state('ownerships.list', {
        url: '^/ownerships',
        controller: 'OwnershipsListCtrl',
        templateUrl: '/templates/modules/ownerships-list/list.template.html'
      })

      .state('files', {
        abstract: true,
        url: '^/files',
        template: '<div ui-view />'
      })

      .state('files.explorer', {
        url: '?source&directory&deleted',
        reloadOnSearch: false,
        controller: 'FileExplorerCtrl',
        templateUrl: '/templates/modules/files-explorer/explorer.template.html'
      })

      .state('mediaScans', {
        abstract: true,
        url: '^/mediaScanning',
        template: '<div ui-view />'
      })

      .state('mediaScans.list', {
        url: '',
        reloadOnSearch: false,
        controller: 'MediaScansListCtrl',
        templateUrl: '/templates/modules/media-scans-list/list.template.html'
      })

      .state('mediaUrls', {
        abstract: true,
        url: '^/mediaScraping',
        template: '<div ui-view />'
      })

      .state('mediaUrls.list', {
        url: '?show&warnings',
        reloadOnSearch: false,
        controller: 'MediaUrlsListCtrl',
        templateUrl: '/templates/modules/media-urls-list/list.template.html'
      })

      .state('images', {
        abstract: true,
        url: '^/images',
        template: '<div ui-view />'
      })

      .state('images.missing', {
        url: '/missing',
        templateUrl: '/templates/modules/images-missing/missing.template.html'
      })

      .state('events', {
        abstract: true,
        url: '^/events',
        template: '<div ui-view />'
      })

      .state('events.list', {
        url: '^/events',
        controller: 'EventsListCtrl',
        templateUrl: '/templates/modules/events-list/list.template.html'
      })

      .state('status', {
        url: '^/status',
        controller: 'StatusCtrl',
        templateUrl: '/templates/modules/status/status.template.html'
      })

      .state('users', {
        abstract: true,
        url: '^/users',
        template: '<div ui-view />'
      })

      .state('users.list', {
        url: '^/users',
        controller: 'UsersListCtrl',
        templateUrl: '/templates/modules/users-list/list.template.html'
      })

      .state('users.new', {
        url: '/new',
        controller: 'NewUserCtrl',
        templateUrl: '/templates/modules/users-new/new.template.html'
      })

      .state('users.edit', {
        url: '/:id',
        controller: 'EditUserCtrl',
        templateUrl: '/templates/modules/users-edit/edit.template.html'
      })

      .state('collection', {
        url: '^/:userName/:collectionName',
        controller: 'CollectionCtrl',
        templateUrl: '/templates/modules/collections-show/show.template.html'
      })

    ;

  })

;
