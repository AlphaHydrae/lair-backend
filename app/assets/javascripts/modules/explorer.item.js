angular.module('lair.explorer.item', [ 'lair.api', 'lair.auth' ])

  .directive('explorerItem', function() {
    return {
      templateUrl: '/templates/explorer-item.html',
      controller: 'ExplorerItemCtrl',
      scope: {
        item: '=',
        params: '='
      }
    };
  })

  .controller('ExplorerItemCtrl', function(api, auth, explorer, $log, $scope, $state) {

    $scope.currentUser = auth.currentUser;
    auth.addAuthFunctions($scope);

    $scope.showPart = showPart;

    function fetchLanguages() {
      return api({
        url: '/languages'
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

    $scope.item.parts = [];

    $scope.edit = function(item) {
      explorer.close();
      $state.go('items.edit', {
        itemId: item.id
      });
    };

    $scope.createPart = function(item) {
      explorer.close();
      $state.go('parts.create', {
        itemId: item.id
      });
    };

    function fetchParts(start) {

      start = start || 0;

      var params = {
        itemId: $scope.item.id,
        number: 50,
        start: start
      };

      if ($scope.params) {
        _.defaults(params, $scope.params);
      }

      api({
        url: '/parts',
        params: params
      }).then(function(res) {
        addParts(res.data);
        if (res.pagination().hasMorePages()) {
          fetchParts(start + res.data.length);
        }
      });
    }

    function addParts(parts) {
      _.each(parts, function(part) {
        var parts = [ $scope.languageNames[part.language] ];

        if (part.edition) {
          parts.push(part.edition + ' Edition');
        }

        if (part.publisher) {
          parts.push('(' + part.publisher + ')');
        }

        var groupName = _.compact(parts).join(' ');
        groupName = groupName.length ? groupName : 'Other';

        if (!_.findWhere($scope.item.parts, { name: groupName })) {
          $scope.item.parts.push({ name: groupName, parts: [] });
        }

        var groupData = _.findWhere($scope.item.parts, { name: groupName });
        groupData.parts.push(part);
      });
    }

    function showPart(part) {
      explorer.open('parts', part);
    }

    fetchLanguages().then(fetchParts);

    $scope.languageName = function(languageTag) {
      return $scope.languageNames ? $scope.languageNames[languageTag] : '-';
    };
  })

  .controller('ItemPartGroupCtrl', function($scope) {
    $scope.currentUserOwnsAny = function(parts) {
      return !!_.find(parts, function(part) {
        return part.ownedByMe;
      });
    };
  })

  .controller('YieldGroupDialogCtrl', function(api, auth, $log, $q, $scope) {

    $scope.dateOptions = {
      dateFormat: 'yy-mm-dd',
      maxDate: new Date()
    };

    $scope.yieldData = {
      yieldedAt: new Date()
    };

    $scope.$watch('ownerships', function(value) {
      if (value) {
        _.each(value, function(ownership) {
          var gottenAt = moment(ownership.gottenAt);
          if (!$scope.dateOptions.minDate) {
            $scope.dateOptions.minDate = gottenAt.toDate();
          } else if (gottenAt.isAfter($scope.dateOptions.minDate)) {
            $scope.dateOptions.minDate = gottenAt.toDate();
          }
        });
      }
    }, true);

    api({
      url: '/ownerships',
      params: {
        partIds: _.pluck($scope.group.parts, 'id'),
        userId: auth.currentUser.id,
        owned: true
      }
    }).then(function(res) {
      $scope.ownerships = res.data;
      $log.debug('Found ' + res.data.length + ' ownerships for ' + $scope.group.parts.length + ' parts (for the current user)');
    });

    $scope.yield = function() {

      $scope.saved = false;

      $q.all(_.map($scope.ownerships, function(ownership) {
        return api({
          method: 'PATCH',
          url: '/ownerships/' + ownership.id,
          data: $scope.yieldData
        }).then(function() {
          var part = _.findWhere($scope.group.parts, { id: ownership.partId });
          if (part) {
            part.ownedByMe = false;
          }
        });
      })).then(function(res) {
        $scope.saved = true;
      });
    };
  })

;
