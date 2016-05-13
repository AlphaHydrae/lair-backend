angular.module('lair.items.form').controller('ItemFormCtrl', function(api, forms, $log, $modal, $q, items, $scope, $state, $stateParams) {

  $scope.itemTypes = items.types;

  if ($scope.item) {
    $scope.works = _.compact([ $scope.item.work ]);
  }

  $scope.$on('item', function(item) {
    $scope.works = [ item.work ];
  });

  $scope.$watch('modifiedItem.type', function(value) {
    if (value == 'volume') {
      delete $scope.modifiedItem.audioLanguages;
      delete $scope.modifiedItem.subtitleLanguages;
      delete $scope.modifiedItem.issn;
    } else if (value == 'issue') {
      delete $scope.modifiedItem.audioLanguages;
      delete $scope.modifiedItem.subtitleLanguages;
      delete $scope.modifiedItem.version;
      delete $scope.modifiedItem.isbn;
    } else if (value == 'video') {
      delete $scope.modifiedItem.publisher;
      delete $scope.modifiedItem.version;
      delete $scope.modifiedItem.isbn;
      delete $scope.modifiedItem.issn;
    }
  });

  $scope.$watch('modifiedItem.workId', function(value) {
    if (value) {
      var newWork = _.findWhere($scope.works, { id: $scope.modifiedItem.workId });
      if (newWork) {
        $scope.modifiedItem.work = newWork;
        $scope.modifiedItem.titleId = newWork.titles[0].id;

        $scope.itemTypes = items.typesForWork(newWork);
        if (!$scope.modifiedItem.type || !_.includes($scope.itemTypes, $scope.modifiedItem.type)) {
          $scope.modifiedItem.type = $scope.itemTypes[0];
        }
      }
    }
  });

  $scope.multiItem = false;
  var multiItemActive = false;

  $scope.$watch('modifiedItem', function(value) {
    if (value) {
      $scope.multiItem = value.start !== undefined && value.end !== undefined && value.start != value.end;
      multiItemActive = true;
    }
  });

  $scope.$watch('modifiedItem.start', function(value) {
    if (multiItemActive && value !== undefined && !$scope.multiItem) {
      $scope.modifiedItem.end = $scope.modifiedItem.start;
    }
  });

  $scope.$watch('multiItem', function(value) {
    if (!multiItemActive || value === undefined) {
      return;
    }

    if (value && $scope.modifiedItem && $scope.modifiedItem.start !== undefined && $scope.modifiedItem.start == $scope.modifiedItem.end) {
      $scope.modifiedItem.end++;
    } else if (!value) {
      $scope.modifiedItem.end = $scope.modifiedItem.start;
    }
  });

  $scope.$watchGroup([ 'modifiedItem.workId', 'modifiedItem.language', 'modifiedItem.start', 'modifiedItem.end', 'modifiedItem.publisher' ], function(values) {

    delete $scope.duplicateItems;

    var workId = values[0],
        language = values[1],
        start = values[2],
        end = values[3],
        publisher = values[4];

    if (!workId || !language || (!start && start !== 0) || (!end && end !== 0)) {
      return;
    }

    api({
      url: '/items',
      params: {
        workId: workId,
        language: language,
        rangeStart: start,
        rangeEnd: end
      }
    }).then(function(res) {
      $scope.duplicateItems = _.filter(res.data, function(item) {
        return !$scope.modifiedItem.id || $scope.modifiedItem.id != item.id;
      });
    });
  });

  $scope.selectImage = function() {
    modal = $modal.open({
      controller: 'SelectImageCtrl',
      templateUrl: '/templates/modules/images-select/select.template.html',
      scope: $scope,
      size: 'lg'
    });

    modal.result.then(function(image) {
      $scope.modifiedItem.image = image;
    });
  };

  $q.all(fetchEditions(), fetchFormats(), fetchLanguages(), fetchPublishers());

  $scope.fetchWorks = function(search) {
    if (!search || !search.trim().length) {
      $scope.works = $scope.item.workId ? [ $scope.item.work ] : [];
      return;
    }

    api({
      url: '/works',
      params: {
        number: 100,
        search: search
      }
    }).then(function(res) {
      $scope.works = res.data;
    }, function(res) {
      $log.warn('Could not fetch works matching "' + search + '"');
      $log.debug(res);
    });
  };

  $scope.itemChanged = function() {
    return !forms.dataEquals($scope.item, $scope.modifiedItem, 'work');
  };

  $scope.languageName = function(tag) {
    if (!$scope.languages) {
      return tag;
    }

    var language = _.findWhere($scope.languages, { tag: tag });
    return language ? language.name : tag;
  };

  function fetchPublishers() {
    return api({
      url: '/itemPublishers'
    }).then(function(res) {
      $scope.publishers = res.data;
    }, function(res) {
      $log.warn('Could not fetch item publishers');
      $log.debug(res);
    });
  }

  function fetchEditions() {
    return api({
      url: '/itemEditions'
    }).then(function(res) {
      $scope.editions = res.data;
    }, function(res) {
      $log.warn('Could not fetch item editions');
      $log.debug(res);
    });
  }

  function fetchFormats() {
    return api({
      url: '/itemFormats'
    }).then(function(res) {
      $scope.formats = res.data;
    }, function(res) {
      $log.warn('Could not fetch item formats');
      $log.debug(res);
    });
  }

  function fetchLanguages() {
    return api({
      url: '/languages'
    }).then(function(res) {
      $scope.languages = res.data;
    }, function(res) {
      // TODO: handle error
      $log.warn('Could not fetch languages');
      $log.debug(res);
    });
  }
});
