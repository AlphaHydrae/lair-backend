angular.module('lair.home', ['lair.api', 'infinite-scroll'])

  .run(function() {
    angular.module('infinite-scroll').value('THROTTLE_MILLISECONDS', 1000);
  })

  .controller('HomeController', ['ApiService', '$modal', '$scope', '$state', function($api, $modal, $scope, $state) {

    var modal,
        page = 1,
        index = 0;

    $scope.items = [];
    $scope.itemsLoading = false;
    $scope.noMoreItems = false;
    $scope.itemCategories = [ 'anime', 'book', 'manga', 'movie', 'show' ];

    $scope.searchItems = function() {
      page = 1;
      index = 0;
      $scope.items = [];
      $scope.itemsLoading = false;
      $scope.noMoreItems = false;
      $scope.getNextItems();
    };

    function addItems(items) {
      // TODO: handle already fetched items
      _.each(items, function(item) {
        $scope.items.push(item);
        index++;
      });
    }

    $scope.getNextItems = function() {
      if ($scope.noMoreItems) {
        return;
      }

      $scope.itemsLoading = true;

      $api.http({
        method: 'GET',
        url: '/api/items',
        params: {
          page: page,
          pageSize: page == 1 ? 60 : 12,
          search: $scope.itemSearchQuery,
          category: $scope.itemSearchCategory
        }
      }).then(function(response) {
        if (response.data.length) {
          if (page == 1) {
            page += 5;
          } else {
            page++;
          }
          $scope.itemsLoading = false;
          addItems(response.data);
        } else {
          $scope.noMoreItems = true;
        }
        //params.total(response.headers('X-Pagination-Total'));
      });
      // TODO: handle failure
    };

    $scope.$on('$stateChangeSuccess', function(event, toState, toParams) {
      if (toState.name == 'std.home.item') {
        if ($scope.item) {
          showModal();
        } else {
          $api.http({
            method: 'GET',
            url: '/api/items/' + toParams.itemId
          }).then(function(response) {
            $scope.item = response.data;
            showModal();
          });
          // TODO: handle failure
        }
      }
    });

    $scope.show = function(item) {
      $scope.item = item;
      $state.go('std.home.item', {
        itemId: item.id
      });
    };

    $scope.edit = function(item) {
      modal.dismiss('edit');
      $state.go('std.items.edit', {
        itemId: item.id
      });
    };

    $scope.editPart = function(part) {
      modal.dismiss('edit');
      $state.go('std.parts.edit', {
        partId: part.id
      });
    };

    $scope.createPart = function(item) {
      modal.dismiss('edit');
      $state.go('std.parts.create', {
        itemId: item.id
      });
    };

    function showModal() {

      modal = $modal.open({
        controller: 'ItemDialogController',
        templateUrl: '/templates/itemDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(undefined, function(reason) {
        if (reason != 'edit') {
          delete $scope.item;
          $state.go('std.home');
        }
      });
    }
  }])

  .controller('ItemDialogController', ['ApiService', '$log', '$scope', function($api, $log, $scope) {

    // FIXME: close when state changes

    function fetchLanguages() {
      return $api.http({
        url: '/api/languages'
      }).then(function(res) {
        $scope.languageNames = _.reduce(res.data, function(memo, language) {
          memo[language.tag] = language.name;
          return memo;
        }, {});
      }, function(res) {
        $log.warn('Could not fetch languages');
        $log.debug(res);
      });
    }

    $scope.item.parts = [];

    function fetchParts(page) {

      page = page || 1;

      $api.http({
        method: 'GET',
        url: '/api/parts',
        params: {
          itemId: $scope.item.id,
          pageSize: 50,
          page: page
        }
      }).then(function(res) {
        addParts(res.data);
        if (res.pagination().hasMorePages()) {
          fetchParts(page + 1);
        }
      });
    }

    function addParts(parts) {
      _.each(parts, function(part) {
        var parts = [ $scope.languageNames[part.language] ];

        if (part.edition) {
          parts.push(part.edition + ' Edition');
        }

        if (part.publisher) {
          parts.push('(' + part.publisher + ')');
        }

        var tabName = _.compact(parts).join(' ');
        tabName = tabName.length ? tabName : 'Other';

        if (!_.findWhere($scope.item.parts, { name: tabName })) {
          $scope.item.parts.push({ name: tabName, parts: [] });
        }

        var tabData = _.findWhere($scope.item.parts, { name: tabName });
        tabData.parts.push(part);
      });
    }

    fetchLanguages().then(fetchParts);

    $scope.formatIsbn = function(isbn) {
      return isbn ? ISBN.hyphenate(isbn) : '-';
    };

    $scope.languageName = function(languageTag) {
      return $scope.languageNames ? $scope.languageNames[languageTag] : '-';
    };

    $scope.$on('ownership', function(event, ownership, part) {
      // FIXME: move this to OwnDialogCtrl
      $api.http({
        method: 'POST',
        url: '/api/ownerships',
        data: ownership
      }).then(function() {
        part.ownedByMe = true;
      }, function(err) {
        $log.warn('Could not create ownership for part ' + part.id);
        $log.debug(err);
      });
    });
  }])

  .controller('OwnDialogCtrl', ['$scope', function($scope) {

    $scope.dateOptions = {
      dateFormat: 'yy-mm-dd'
    };

    $scope.ownership = {
      partId: $scope.part.id,
      gottenAt: new Date()
    };

    $scope.create = function() {
      $scope.$emit('ownership', $scope.ownership, $scope.part);
    };
  }])

  .directive('ownDialog', ['$compile', function ($compile) {
    return function(scope, element, attrs) {

      var shown = false,
          contentTemplate = _.template('<form ng-controller="OwnDialogCtrl" ng-submit="create()" class="ownDialog"><div class="form-group"><label>Owned since</label><input class="form-control" ui-date="dateOptions" ng-model="ownership.gottenAt" /></div><button type="submit" class="btn btn-primary btn-block">Add</button></form>');

      element.on('mouseenter', function() {
        if (!shown) {
          element.tooltip('show');
        }
      });

      element.on('mouseleave', function() {
        element.tooltip('hide');
      });

      scope.$on('ownership', function() {
        element.popover('hide');
        shown = false;
      });

      element.on('click', function() {
        element.popover(shown ? 'hide' : 'show');
        element.tooltip(shown ? 'show' : 'hide');
        shown = !shown;
      });

      element.tooltip({
        trigger: 'manual',
        title: 'I own this'
      });

      element.popover({
        trigger: 'manual',
        placement: 'auto',
        content: $compile(contentTemplate({}))(scope),
        html: true,
        template: '<div class="popover ownDialogPopover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
      });
    };
  }])
;
