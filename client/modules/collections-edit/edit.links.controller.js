angular.module('lair.collections.edit').controller('EditCollectionLinksCtrl', function(api, $log, $q, $scope) {

  var selectedRecords = {
    works: {},
    items: {},
    ownerships: {}
  };

  $scope.records = [];
  $scope.displayOptions = {};

  $scope.select = selectRecord;
  $scope.selected = isRecordSelected;
  $scope.selectAll = selectAllRecords;
  $scope.unselectAll = unselectAllRecords;
  $scope.allSelected = areAllRecordsSelected;
  $scope.noneSelected = areNoRecordsSelected;

  _.each([ 'works', 'items', 'ownerships' ], fetchLinks);

  function fetchLinks(type) {
    api.all({
      url: '/collections/' + $scope.collection.id + '/' + type
    }).then(function(records) {
      _.each(records, function(link) {
        selectedRecords[type][link[inflection.singularize(type) + 'Id']] = link;
      });
    });
  }

  function selectAllRecords() {
    if (!$scope.records.length) {
      return;
    } else if ($scope.records.length > 100) {
      return alert('There are more than 100 records displayed. Please refine your search.');
    }

    var type = $scope.displayOptions.type,
        records = $scope.records.slice();

    records = _.filter(records, function(record) {
      return !isRecordSelected(type, record);
    });

    $q.all(_.map(records, function(record) {
      return createCollectionLink(type, record);
    })).then(function() {
      $log.debug('Successfully selected ' + records.length + ' ' + type);
    }, function(res) {
      $log.warn('Could not select all displayed records');
      $log.debug(res);
    });
  }

  function unselectAllRecords() {
    if (!$scope.records.length) {
      return;
    }

    var type = $scope.displayOptions.type,
        records = $scope.records.slice();

    records = _.filter(records, function(record) {
      return isRecordSelected(type, record);
    });

    $q.all(_.map(records, function(record) {
      return deleteCollectionLink(type, record);
    })).then(function() {
      $log.debug('Successfully unselected ' + records.length + ' ' + type);
    }, function(res) {
      $log.warn('Could not unselect all displayed records');
      $log.debug(res);
    });
  }

  function selectRecord(type, record) {
    if (!selectedRecords[type][record.id]) {
      createCollectionLink(type, record);
    } else {
      deleteCollectionLink(type, record);
    }

    return true;
  }

  function isRecordSelected(type, record) {
    if (selectedRecords[type][record.id]) {
      return true;
    } else if (type == 'items' && selectedRecords.works[record.workId]) {
      return 'transitive';
    } else if (type == 'ownerships' && selectedRecords.items[record.itemId]) {
      return 'transitive';
    } else if (type == 'ownerships' && record.item && selectedRecords.works[record.item.workId]) {
      return 'transitive';
    } else {
      return false;
    }
  }

  function areAllRecordsSelected() {
    return _.every($scope.records, function(record) {
      return $scope.displayOptions.type && isRecordSelected($scope.displayOptions.type, record);
    });
  }

  function areNoRecordsSelected() {
    return _.every($scope.records, function(record) {
      return $scope.displayOptions.type && !isRecordSelected($scope.displayOptions.type, record);
    });
  }

  function createCollectionLink(type, record) {

    var data = {};
    data[inflection.singularize(type) + 'Id'] = record.id;

    return api({
      method: 'POST',
      url: '/collections/' + $scope.collection.id + '/' + type,
      data: data
    }).then(function(res) {
      selectedRecords[type][record.id] = res.data;
      return res.data;
    });
  }

  function deleteCollectionLink(type, record) {
    return api({
      method: 'DELETE',
      url: '/collections/' + $scope.collection.id + '/' + type + '/' + selectedRecords[type][record.id].id
    }).then(function() {
      delete selectedRecords[type][record.id];
    });
  }
});
