angular.module('lair.parts.create', ['lair.parts.form'])

  .controller('CreatePartCtrl', ['ApiService', '$log', '$modal', 'moment', '$q', '$scope', '$state', '$stateParams', function($api, $log, $modal, moment, $q, $scope, $state, $stateParams) {

    function parsePart(part) {
      return _.extend({}, part, {
        tags: _.reduce(_.keys(part.tags).sort(), function(memo, key) {
          memo.push({ key: key, value: part.tags[key] });
          return memo;
        }, [])
      });
    }

    function dumpPart(part) {
      return _.extend({}, part, {
        tags: _.reduce(part.tags, function(memo, tag) {
          memo[tag.key] = tag.value;
          return memo;
        }, {})
      });
    }

    $scope.part = parsePart({
      tags: []
    });

    if ($stateParams.itemId) {
      $api.http({
        url: '/api/items/' + $stateParams.itemId
      }).then(function(res) {
        $scope.part.item = res.data;
        $scope.part.itemId = res.data.id;
        reset();
        prefill(res.data);
      }, function(err) {
        $log.warn('Could not fetch item ' + $stateParams.itemId);
        $log.debug(err);
      });
    } else {
      reset();
    }

    function prefill(item) {
      $api.http({
        url: '/api/parts',
        params: {
          itemId: item.id,
          pageSize: 1,
          latest: 1
        }
      }).then(function(res) {
        if (res.data.length) {

          var part = res.data[0];
          $scope.modifiedPart.language = part.language;
          $scope.modifiedPart.edition = part.edition;
          $scope.modifiedPart.publisher = part.publisher;
          $scope.modifiedPart.format = part.format;
          $scope.modifiedPart.year = part.year;
          $scope.modifiedPart.originalYear = part.originalYear;

          if (part.titleId) {
            $scope.modifiedPart.titleId = part.titleId;
          }

          if (part.start) {
            $scope.modifiedPart.start = part.end + 1;
          }
        }
      });
    }

    function reset() {
      $scope.modifiedPart = angular.copy($scope.part);
      $scope.$broadcast('part', $scope.part);
    }

    $scope.imageSearchesResource = '/api/image-searches';

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
      save().then(function(part) {
        edit(part);
      });
    };

    $scope.saveAndAddAnother = function() {
      save().then(addAnother);
    };

    $scope.cancel = function() {
      if ($stateParams.itemId) {
        $state.go('std.home.item', { itemId: $stateParams.itemId });
      } else {
        $state.go('std.home');
      }
    };

    function save() {

      var promise = $q.when().then(savePart);
      if ($scope.ownershipOptions.ownedByMe) {
        promise.then(saveOwnership);
      }

      return promise;
    }

    function savePart() {
      return $api.http({
        method: 'POST',
        url: '/api/parts',
        data: dumpPart($scope.modifiedPart)
      }).then(function(res) {
        return res.data;
      }, function(res) {
        $log.warn('Could not update part ' + $stateParams.partId);
        $log.debug(res);
        return $q.reject(res);
      });
    }

    function saveOwnership(part) {
      return $api.http({
        method: 'POST',
        url: '/api/ownerships',
        data: {
          userId: $scope.currentUser.id,
          partId: part.id,
          gottenAt: moment($scope.ownership.gottenAt).toISOString()
        }
      }).then(function(res) {
        return part;
      }, function(res) {
        $log.warn('Could not create ownership');
        $log.debug(res);
        return $q.reject(res);
      });
    }

    function edit(part) {
      $state.go('std.parts.edit', { partId: part.id });
    }

    function addAnother() {

      delete $scope.modifiedPart.length;
      delete $scope.modifiedPart.isbn;
      delete $scope.modifiedPart.image;

      var rangeSize = $scope.modifiedPart.end - $scope.modifiedPart.start;
      $scope.modifiedPart.start = $scope.modifiedPart.end + 1;
      $scope.modifiedPart.end = $scope.modifiedPart.start + rangeSize;
    }
  }])
;
