angular.module('lair.gallery').controller('GalleryCtrl', function(auth, explorer, works, $scope, users) {

  $scope.currentUser = auth;
  auth.addAuthFunctions($scope);

  $scope.resourcesData = [
    { name: 'works', url: '/works', params: { withItem: null } },
    { name: 'items', url: '/items', params: { withItem: null } },
    { name: 'ownerships', url: '/ownerships', params: { withItem: 1, withUser: 1 } }
  ];

  function setResourceData(name) {
    $scope.dataList.type = name;

    var options = _.findWhere($scope.resourcesData, { name: name });
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
    type: 'works',
    records: [],
    httpSettings: {
      url: '/works',
      params: {}
    },
    options: {}
  };

  $scope.$watchGroup([ 'records', 'displayEnabled', 'dataList.type' ], function(values) {
    $scope.displayType = values[2] || 'works';
    $scope.dataList.records = values[0] !== undefined ? values[0] : $scope.dataList.records;
    setResourceData(values[2] || 'works');
    $scope.dataList.options.enabled = values[1] !== undefined ? values[1] : true;
  });

  var categories,
      ownerIds;

  $scope.dataFilters = {
    resource: 'works'
  };

  if ($scope.collection) {

    categories = $scope.collection.restrictions.categories;
    ownerIds = $scope.collection.restrictions.ownerIds;

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

    if ($scope.collection.defaultFilters.resource) {
      $scope.dataFilters.resource = $scope.collection.defaultFilters.resource;
    }

    $scope.dataFilters.search = $scope.collection.defaultFilters.search;
    $scope.dataFilters.categories = $scope.collection.defaultFilters.categories;
    $scope.dataFilters.ownerIds = $scope.collection.defaultFilters.ownerIds;

    setDataFilters($scope.dataFilters);
  }

  $scope.$watch('dataFilters', setDataFilters, true);

  function setDataFilters(filters) {
    if (filters.resource) {
      $scope.dataList.type = filters.resource;
    }

    if (filters.search) {
      $scope.dataList.httpSettings.params.search = filters.search;
    } else {
      delete $scope.dataList.httpSettings.params.search;
    }

    $scope.dataList.httpSettings.params.categories = filters.categories && filters.categories.length ? filters.categories : categories;
    $scope.dataList.httpSettings.params.ownerIds = filters.ownerIds && filters.ownerIds.length ? filters.ownerIds : ownerIds;
  }

  $scope.onSelectProxy = selectRecord;
  $scope.selectedProxy = isRecordSelected;

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
    if ($scope.dataList.type == 'works') {
      explorer.open('works', record, { params: $scope.dataList.httpSettings.params });
    } else if ($scope.dataList.type == 'items') {
      explorer.open('items', record, { params: $scope.dataList.httpSettings.params });
    } else if ($scope.dataList.type == 'ownerships') {
      explorer.open('items', record.item, { params: $scope.dataList.httpSettings.params });
    }
  }
});
