angular.module('lair.items.new').controller('NewItemCtrl', function(api, $log, moment, items, $q, $scope, $state, $stateParams) {

  function parseItem(item) {
    return _.extend({}, item, {
      properties: _.reduce(_.keys(item.properties).sort(), function(memo, key) {
        memo.push({ key: key, value: item.properties[key] });
        return memo;
      }, [])
    });
  }

  function dumpItem(item) {
    return _.extend({}, item, {
      properties: _.reduce(item.properties, function(memo, property) {
        memo[property.key] = property.value;
        return memo;
      }, {})
    });
  }

  $scope.item = parseItem({
    type: items.types[0],
    properties: []
  });

  if ($stateParams.workId) {
    api({
      url: '/works/' + $stateParams.workId
    }).then(function(res) {
      $scope.item.work = res.data;
      $scope.item.workId = res.data.id;
      reset();
      prefill(res.data);
    }, function(err) {
      $log.warn('Could not fetch work ' + $stateParams.workId);
      $log.debug(err);
    });
  } else {
    reset();
  }

  function prefill(work) {
    api({
      url: '/items',
      params: {
        workId: work.id,
        number: 1,
        latest: 1
      }
    }).then(function(res) {
      if (res.data.length) {

        var item = res.data[0];
        $scope.modifiedItem.language = item.language;
        $scope.modifiedItem.edition = item.edition;
        $scope.modifiedItem.publisher = item.publisher;
        $scope.modifiedItem.format = item.format;
        $scope.modifiedItem.releaseDate = item.releaseDate;
        $scope.modifiedItem.originalReleaseDate = item.originalReleaseDate;
        $scope.modifiedItem.issn = item.issn;

        if (item.titleId) {
          $scope.modifiedItem.titleId = item.titleId;
        }

        if (item.start) {
          $scope.modifiedItem.start = item.end + 1;
        }
      }
    });
  }

  function reset() {
    $scope.modifiedItem = angular.copy($scope.item);
    $scope.$broadcast('item', $scope.item);
  }

  $scope.dateOptions = {
    dateFormat: 'yy-mm-dd'
  };

  $scope.ownership = {
    gottenAt: new Date()
  };

  $scope.ownershipOptions = {
    ownedByMe: false
  };

  $scope.save = function() {
    save().then(function(item) {
      edit(item);
    });
  };

  $scope.saveAndAddAnother = function() {
    save().then(addAnother);
  };

  $scope.cancel = function() {
    if ($stateParams.workId) {
      // TODO: go back
      $state.go('home');
    } else {
      $state.go('home');
    }
  };

  function save() {

    var promise = $q.when().then(saveItem);
    if ($scope.ownershipOptions.ownedByMe) {
      promise.then(saveOwnership);
    }

    return promise;
  }

  function saveItem() {
    return api({
      method: 'POST',
      url: '/items',
      data: dumpItem($scope.modifiedItem)
    }).then(function(res) {
      return res.data;
    }, function(res) {
      $log.warn('Could not update item ' + $stateParams.itemId);
      $log.debug(res);
      return $q.reject(res);
    });
  }

  function saveOwnership(item) {
    return api({
      method: 'POST',
      url: '/ownerships',
      data: {
        userId: $scope.currentUser.id,
        itemId: item.id,
        gottenAt: moment($scope.ownership.gottenAt).toISOString()
      }
    }).then(function(res) {
      return item;
    }, function(res) {
      $log.warn('Could not create ownership');
      $log.debug(res);
      return $q.reject(res);
    });
  }

  function edit(item) {
    $state.go('items.edit', { itemId: item.id });
  }

  function addAnother() {

    delete $scope.modifiedItem.length;
    delete $scope.modifiedItem.isbn;
    delete $scope.modifiedItem.image;

    var rangeSize = $scope.modifiedItem.end - $scope.modifiedItem.start;
    $scope.modifiedItem.start = $scope.modifiedItem.end + 1;
    $scope.modifiedItem.end = $scope.modifiedItem.start + rangeSize;
  }
});
