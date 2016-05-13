angular.module('lair.collections.edit', [ 'lair.collections.form', 'lair.forms', 'lair.users' ])

  .controller('EditCollectionCtrl', function(api, $scope, $state, $stateParams, users) {

    $scope.save = _.partial(updateCollection, false);
    $scope.saveAndMakePublic = _.partial(updateCollection, true);
    $scope.delete = deleteCollection;
    $scope.reset = resetModifiedCollection;

    $scope.tabs = {
      restrictions: true,
      manualSelection: false
    };

    $scope.$watch('collection', resetModifiedCollection);

    $scope.$watch('modifiedCollection.public', function(value) {
      if (value === false) {
        $scope.modifiedCollection.featured = false;
      }
    });

    api({
      url: '/collections/' + $stateParams.id
    }).then(function(res) {
      $scope.collection = res.data;
    });

    users.fetchAllUsers().then(function(users) {
      $scope.allUsers = users;
    });

    function updateCollection(makePublic) {

      var data = _.extend({}, $scope.modifiedCollection);

      if (makePublic) {
        data.public = true;
      }

      api({
        method: 'PATCH',
        url: '/collections/' + $stateParams.id,
        data: data
      }).then(function(res) {
        $scope.collection = res.data;
      });
    }

    function deleteCollection(collection) {
      if (!confirm('Are you sure you want to delete "' + $scope.collection.displayName + '"?')) {
        return;
      }

      api({
        method: 'DELETE',
        url: '/collections/' + $scope.collection.id
      }).then(function() {
        $state.go('collections.list');
      });
    }

    function resetModifiedCollection() {
      $scope.modifiedCollection = angular.copy($scope.collection);
    }
  })

  .directive('editCollectionLinks', function() {
    return {
      restrict: 'E',
      templateUrl: '/templates/collections-edit-links.html',
      controller: 'EditCollectionLinksCtrl',
      scope: {
        collection: '=',
        enabled: '='
      }
    };
  })

  .controller('EditCollectionLinksCtrl', function(api, $log, $q, $scope) {

    var selectedRecords = {
      items: {},
      parts: {},
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

    _.each([ 'items', 'parts', 'ownerships' ], fetchLinks);

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
      } else if (type == 'parts' && selectedRecords.items[record.itemId]) {
        return 'transitive';
      } else if (type == 'ownerships' && selectedRecords.parts[record.partId]) {
        return 'transitive';
      } else if (type == 'ownerships' && record.part && selectedRecords.items[record.part.itemId]) {
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
  })

;
