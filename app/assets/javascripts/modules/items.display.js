angular.module('lair.items.display', [ 'lair.auth', 'lair.explorer', 'lair.infinite', 'lair.users' ])

  .directive('itemsDisplay', function() {
    return {
      restrict: 'E',
      templateUrl: '/templates/items-display.html',
      controller: 'ItemsDisplayCtrl',
      scope: {
        records: '=',
        collection: '=',
        collectionModified: '=',
        displayEnabled: '=',
        displayType: '=',
        onSelect: '&',
        selected: '&'
      }
    };
  })

  .controller('ItemsDisplayCtrl', function(auth, explorer, $scope, users) {

    $scope.currentUser = auth;
    auth.addAuthFunctions($scope);

    $scope.dataTypeChoices = [
      { name: 'items', url: '/items', params: { withPart: null } },
      { name: 'parts', url: '/parts', params: { withPart: null } },
    ];

    // FIXME: keep data type choices up to date when user logs in/out
    if (auth.currentUser) {
      $scope.dataTypeChoices.push({ name: 'ownerships', url: '/ownerships', params: { withPart: 1, withUser: 1 } });
    }

    function setDataType(name) {
      $scope.dataList.type = name;

      var options = _.findWhere($scope.dataTypeChoices, { name: name });
      $scope.dataList.httpSettings.url = options.url;

      _.each(options.params, function(value, key) {
        if (value === null) {
          delete $scope.dataList.httpSettings.params[key];
        } else {
          $scope.dataList.httpSettings.params[key] = value;
        }
      });
    }

    $scope.dataList = {
      records: [],
      httpSettings: {
        url: '/items',
        params: {}
      },
      options: {}
    };

    $scope.$watchGroup([ 'records', 'displayEnabled', 'dataList.type' ], function(values) {
      $scope.displayType = values[2] || 'items';
      $scope.dataList.records = values[0] !== undefined ? values[0] : $scope.dataList.records;
      setDataType(values[2] || 'items');
      $scope.dataList.options.enabled = values[1] !== undefined ? values[1] : true;
    });

    var categories,
        ownerIds;

    if ($scope.collection) {

      categories = $scope.collection.restrictions.categories;
      ownerIds = $scope.collection.restrictions.owners;

      if ($scope.collectionModified) {
        if (categories && categories.length) {
          $scope.dataList.httpSettings.params.categories = categories;
        }

        if (ownerIds && ownerIds.length) {
          $scope.dataList.httpSettings.params.ownerIds = ownerIds;
        }
      } else {
        $scope.dataList.httpSettings.params.collectionId = $scope.collection.id;
      }
    }

    if (!categories) {
      $scope.categoryChoices = [ 'anime', 'book', 'manga', 'movie', 'show' ];
    } else if (categories.length >= 2) {
      $scope.categoryChoices = categories;
    }

    if (!ownerIds) {
      users.fetchAllUsers().then(function(users) {
        $scope.ownerChoices = users;
      });
    } else if (ownerIds.length >= 2) {
      users.fetchUsersById(ownerIds).then(function(users) {
        $scope.ownerChoices = users;
      });
    }

    $scope.onSelectProxy = selectRecord;
    $scope.selectedProxy = isRecordSelected;
    $scope.toggleAdvancedSearch = toggleAdvancedSearch;

    function selectRecord($event, record) {
      $event.preventDefault();

      if (!$scope.onSelect({ type: $scope.dataList.type, record: record })) {
        openExplorerDialog(record);
      }
    }

    function isRecordSelected(record) {
      return $scope.selected({ type: $scope.dataList.type, record: record }) || false;
    }

    function openExplorerDialog(record) {
      if ($scope.dataList.type == 'items') {
        explorer.open('items', record, { params: $scope.dataList.httpSettings.params });
      } else if ($scope.dataList.type == 'parts') {
        explorer.open('parts', record, { params: $scope.dataList.httpSettings.params });
      } else if ($scope.dataList.type == 'ownerships') {
        explorer.open('parts', record.part, { params: $scope.dataList.httpSettings.params });
      }
    }

    function toggleAdvancedSearch() {
      $scope.advancedSearchEnabled = !$scope.advancedSearchEnabled;
    }
  })

;
