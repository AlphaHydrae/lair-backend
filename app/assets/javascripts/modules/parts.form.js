angular.module('lair.parts.form', ['lair.forms', 'lair.images.select'])

  .controller('PartFormCtrl', ['ApiService', '$log', '$modal', '$q', '$scope', '$state', '$stateParams', function($api, $log, $modal, $q, $scope, $state, $stateParams) {

    if ($scope.part) {
      $scope.items = _.compact([ $scope.part.item ]);
    }

    $scope.$on('part', function(part) {
      $scope.items = [ part.item ];
    });

    $scope.$watch('modifiedPart.itemId', function(value) {
      if (value) {
        var newItem = _.findWhere($scope.items, { id: $scope.modifiedPart.itemId });
        if (newItem) {
          $scope.modifiedPart.item = newItem;
        }
      }
    });

    $scope.$watch('modifiedPart.item', function(value) {
      if (value) {
        $scope.modifiedPart.titleId = value.titles[0].id;
      }
    });

    $scope.$watch('modifiedPart.titleId', function(newValue) {
      if (newValue && newValue.trim().length) {
        $scope.modifiedPart.customTitle = null;
        $scope.modifiedPart.customTitleLanguage = null;
      }
    });

    $scope.$watch('modifiedPart.customTitle', function(newValue) {
      if (newValue && newValue.trim().length) {
        $scope.modifiedPart.titleId = null;
      } else if ($scope.part.titleId) {
        $scope.modifiedPart.titleId = $scope.part.titleId;
      }
    });

    $scope.multiPart = false;
    var multiPartActive = false;

    $scope.$watch('modifiedPart', function(value) {
      if (value) {
        $scope.multiPart = value.start !== undefined && value.end !== undefined && value.start != value.end;
        multiPartActive = true;
      }
    });

    $scope.$watch('modifiedPart.start', function(value) {
      if (multiPartActive && value !== undefined && !$scope.multiPart) {
        $scope.modifiedPart.end = $scope.modifiedPart.start;
      }
    });

    $scope.$watch('multiPart', function(value) {
      if (!multiPartActive || value === undefined) {
        return;
      }

      if (value && $scope.modifiedPart && $scope.modifiedPart.start !== undefined && $scope.modifiedPart.start == $scope.modifiedPart.end) {
        $scope.modifiedPart.end++;
      } else if (!value) {
        $scope.modifiedPart.end = $scope.modifiedPart.start;
      }
    });

    $scope.selectImage = function() {
      modal = $modal.open({
        controller: 'SelectImageCtrl',
        templateUrl: '/templates/selectImageDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(function(image) {
        $scope.modifiedPart.image = image;
      });
    };

    $q.all(fetchEditions(), fetchFormats(), fetchLanguages(), fetchPublishers());

    $scope.fetchItems = function(search) {
      if (!search || !search.trim().length) {
        $scope.items = $scope.part.itemId ? [ $scope.part.item ] : [];
        return;
      }

      $api.http({
        url: '/api/items',
        params: {
          pageSize: 100,
          search: search
        }
      }).then(function(res) {
        $scope.items = res.data;
      }, function(res) {
        $log.warn('Could not fetch items matching "' + search + '"');
        $log.debug(res);
      });
    };

    $scope.partChanged = function() {
      return !angular.equals($scope.part, $scope.modifiedPart);
    };

    $scope.addTag = function() {
      $scope.modifiedPart.tags.push({});
    };

    $scope.removeTag = function(tag) {
      $scope.modifiedPart.tags.splice($scope.modifiedPart.tags.indexOf(tag), 1);
    };

    function fetchPublishers() {
      return $api.http({
        url: '/api/bookPublishers'
      }).then(function(res) {
        $scope.publishers = res.data;
      }, function(res) {
        $log.warn('Could not fetch book publishers');
        $log.debug(res);
      });
    }

    function fetchEditions() {
      return $api.http({
        url: '/api/partEditions'
      }).then(function(res) {
        $scope.editions = res.data;
      }, function(res) {
        $log.warn('Could not fetch part editions');
        $log.debug(res);
      });
    }

    function fetchFormats() {
      return $api.http({
        url: '/api/partFormats'
      }).then(function(res) {
        $scope.formats = res.data;
      }, function(res) {
        $log.warn('Could not fetch part formats');
        $log.debug(res);
      });
    }

    function fetchLanguages() {
      return $api.http({
        url: '/api/languages'
      }).then(function(res) {
        $scope.languages = res.data;
      }, function(res) {
        // TODO: handle error
        $log.warn('Could not fetch languages');
        $log.debug(res);
      });
    }
  }])
;
