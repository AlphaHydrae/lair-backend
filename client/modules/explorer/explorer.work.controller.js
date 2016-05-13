angular.module('lair.explorer').controller('ExplorerWorkCtrl', function(api, auth, explorer, $log, $scope, $state) {

  $scope.currentUser = auth.currentUser;
  auth.addAuthFunctions($scope);

  $scope.showItem = showItem;

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

  $scope.work.items = [];

  $scope.edit = function(work) {
    explorer.close();
    $state.go('works.edit', {
      workId: work.id
    });
  };

  $scope.createItem = function(work) {
    explorer.close();
    $state.go('items.new', {
      workId: work.id
    });
  };

  function fetchItems(start) {

    start = start || 0;

    var params = {
      workId: $scope.work.id,
      number: 50,
      start: start
    };

    if ($scope.params) {
      _.defaults(params, $scope.params);
    }

    api({
      url: '/items',
      params: params
    }).then(function(res) {
      addItems(res.data);
      if (res.pagination().hasMorePages()) {
        fetchItems(start + res.data.length);
      }
    });
  }

  function addItems(items) {
    _.each(items, function(item) {
      var parts = [ $scope.languageNames[item.language] ];

      if (item.edition) {
        parts.push(item.edition + ' Edition');
      }

      if (item.publisher) {
        parts.push('(' + item.publisher + ')');
      }

      var groupName = _.compact(parts).join(' ');
      groupName = groupName.length ? groupName : 'Other';

      if (!_.findWhere($scope.work.items, { name: groupName })) {
        $scope.work.items.push({ name: groupName, items: [] });
      }

      var groupData = _.findWhere($scope.work.items, { name: groupName });
      groupData.items.push(item);
    });
  }

  function showItem(item) {
    explorer.open('items', item);
  }

  fetchLanguages().then(fetchItems);

  $scope.languageName = function(languageTag) {
    return $scope.languageNames ? $scope.languageNames[languageTag] : '-';
  };
});
