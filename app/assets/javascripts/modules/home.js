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

    function addItems(items) {
      // TODO: handle already fetched items
      _.each(items, function(item) {
        if (index !== 0 && index % 6 === 0) {
          $scope.items.push({ separator: true });
        }
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
          pageSize: 12
        }
      }).then(function(response) {
        if (response.data.length) {
          page++;
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

    function fetchParts() {
      $api.http({
        method: 'GET',
        url: '/api/parts',
        params: {
          itemId: $scope.item.id
        }
      }).then(function(response) {

        $scope.item.parts = _.reduce(response.data, function(memo, part) {

          var parts = [ $scope.languageNames[part.language] ];

          if (part.edition) {
            parts.push(part.edition + ' Edition');
          }

          if (part.publisher) {
            parts.push('(' + part.publisher + ')');
          }

          var tabName = _.compact(parts).join(' ');
          tabName = tabName.length ? tabName : 'Other';

          if (!_.findWhere(memo, { name: tabName })) {
            memo.push({ name: tabName, parts: [] });
          }

          var tabData = _.findWhere(memo, { name: tabName });
          tabData.parts.push(part);

          return memo;
        }, []);
      });
    }

    fetchLanguages().then(fetchParts);

    $scope.formatIsbn = function(isbn) {
      return isbn ? ISBN.hyphenate(isbn) : '-';
    };

    $scope.languageName = function(languageTag) {
      return $scope.languageNames ? $scope.languageNames[languageTag] : '-';
    };
  }])

;
