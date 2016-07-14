angular.module('lair.media.compare').controller('MediaCompareCtrl', function(api, $log, $q, $scope, titles, works) {

  $scope.filters = {};
  $scope.sources = {};
  $scope.missingWorks = {};
  $scope.missingWorksPercentage = {};

  $scope.fingerprints = {
    user1: [],
    user2: []
  };

  $scope.comparisons = [];

  _.extend($scope, _.pick(works, 'categories'));
  _.extend($scope, _.pick(titles, 'secondaryTitle'));

  api({
    url: '/users'
  }).then(function(res) {
    $scope.users = res.data;
  });

  $scope.$watch('filters.user1', function(value) {
    if (value) {
      $scope.users2 = _.filter($scope.users, function(user) {
        return user.id != value;
      });

      fetchSources(1, value);
    } else {
      delete $scope.users2;
      delete $scope.sources.user1;
    }
  });

  $scope.$watch('filters.user2', function(value) {
    if (value) {
      fetchSources(2, value);
    } else {
      delete $scope.sources.user2;
    }
  });

  $scope.$watchGroup([ 'filters.categories', 'filters.user1', 'filters.user2' ], function(values) {

    var categories = values[0],
        user1Id = values[1],
        user2Id = values[2];

    if (categories && categories.length && user1Id && user2Id) {
      fetchNextMissingWorks(1, user2Id, user1Id);
      fetchNextMissingWorks(2, user1Id, user2Id);
    }
  });

  $scope.$watchGroup([ 'filters.source1', 'filters.source2' ], function(values) {

    var source1Id = values[0],
        source2Id = values[1];

    if (source1Id && source2Id) {
      $scope.comparisons = [];
      fetchNextFingerprints(source1Id, source2Id);
    }
  });

  function fetchNextFingerprints(source1Id, source2Id, start) {

    start = start || 0
    $scope.fetchingFingerprints = true;
    $scope.fetchingFingerprintsPercentage = $scope.fetchingFingerprintsPercentage || 0;

    api({
      url: '/media/fingerprints',
      params: {
        start: start,
        number: 100,
        sourceId: [ source1Id, source2Id ],
        category: $scope.filters.categories
      }
    }).then(function(res) {

      $scope.fetchingFingerprintsPercentage = res.pagination().percentage;

      _.each(res.data, compareFingerprint);

      if (res.pagination().hasMorePages()) {
        fetchNextFingerprints(source1Id, source2Id, start + res.data.length);
      } else {
        $scope.fetchingFingerprints = false;
      }
    });
  }

  function compareFingerprint(fingerprint) {
    if (_.find($scope.missingWorks.user1, { mediaUrlId: fingerprint.mediaUrlId }) || _.find($scope.missingWorks.user2, { mediaUrlId: fingerprint.mediaUrlId })) {
      return;
    }

    var userNumber = fingerprint.sourceId == $scope.filters.source1 ? 1 : 2,
        userFingerprints = $scope.fingerprints['user' + userNumber],
        otherUserNumber = userNumber == 1 ? 2 : 1,
        otherUserFingerprints = $scope.fingerprints['user' + otherUserNumber];

    var correspondingFingerprint = _.find(otherUserFingerprints, { mediaUrlId: fingerprint.mediaUrlId });
    if (correspondingFingerprint) {
      otherUserFingerprints.splice(otherUserFingerprints.indexOf(correspondingFingerprint), 1);
      addFingerprintComparison(userNumber == 1 ? fingerprint : correspondingFingerprint, userNumber == 1 ? correspondingFingerprint : fingerprint);
    } else {
      userFingerprints.push(fingerprint);
    }
  }

  function addFingerprintComparison(f1, f2) {

    var result = 'identical';
    if (f1.contentSize != f2.contentSize || f1.contentFilesCount != f2.contentFilesCount) {
      result = 'contentDifferent';
    } else if (f1.totalSize != f2.totalSize || f1.totalFilesCount != f2.totalFilesCount) {
      result = 'totalDifferent';
    } else {
      return;
    }

    api({
      url: '/works',
      params: {
        mediaUrlId: f1.mediaUrlId
      }
    }).then(function(res) {
      if (!res.data.length) {
        $log.warn('Could not find work for media url ' + f1.mediaUrlId);
        return;
      }

      $scope.comparisons.push({
        work: res.data[0],
        f1: f1,
        f2: f2,
        result: result
      });
    });
  }

  function fetchNextMissingWorks(userNumber, owner, notOwner, start) {

    $scope['fetchingMissingWorksUser' + userNumber] = true;

    if (!start) {
      start = 0;
      $scope.missingWorks['user' + userNumber] = [];
      $scope.missingWorksPercentage['user' + userNumber] = 100;
    }

    api({
      url: '/works',
      params: {
        start: start,
        number: 100,
        categories: $scope.filters.categories,
        ownerIds: [ owner ],
        notOwnedBy: notOwner
      }
    }).then(function(res) {

      $scope.missingWorksPercentage['user' + userNumber] = res.pagination().percentage;
      $scope.missingWorks['user' + userNumber] = $scope.missingWorks['user' + userNumber].concat(res.data);

      if (res.pagination().hasMorePages()) {
        fetchNextMissingWorks(userNumber, owner, notOwner, start + res.data.length);
      } else {
        $scope['fetchingMissingWorksUser' + userNumber] = false;
      }
    });
  }

  function fetchSources(userNumber, userId) {
    api.all({
      url: '/media/sources',
      params: {
        userId: userId
      }
    }).then(function(sources) {
      $scope.sources['user' + userNumber] = sources;
    });
  }
});
