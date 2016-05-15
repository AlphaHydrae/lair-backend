angular.module('lair.explorer').controller('ExplorerWorkCtrl', function(api, auth, explorer, items, languages, $log, $scope, $state, titles) {

  $scope.currentUser = auth.currentUser;
  auth.addAuthFunctions($scope);

  $scope.humanItemLength = items.humanLength;
  _.extend($scope, _.pick(titles, 'secondaryTitle', 'otherTitles'));
  _.extend($scope, _.pick(items, 'humanMainReleaseDate', 'humanSecondaryReleaseDate'));

  $scope.showItem = function(item) {
    explorer.open('items', item);
  };

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

  fetchLanguages().then(fetchItems).then(function(loadedItems) {

    $scope.work.numberOfSpecialItems = _.filter(loadedItems, {
      special: true
    }).length;

    if (_.includes([ 'book', 'manga', 'movie' ], $scope.work.category)) {
      items.groupItems(loadedItems).then(function(groupedItems) {
        $scope.work.groupedItems = groupedItems;
      });
    } else {
      items.orderItems(loadedItems).then(function(orderedItems) {
        $scope.work.orderedItems = orderedItems;
      });
    }
  });

  var languageNamesByTag;
  $scope.languageName = function(tag) {
    return languageNamesByTag ? languageNamesByTag[tag] : undefined;
  };

  function fetchLanguages() {
    return languages.loadLanguageNamesByTag().then(function(result) {
      languageNamesByTag = result;
      return languageNamesByTag;
    });
  }

  function fetchItems() {

    var params = {
      workId: $scope.work.id,
      number: 100
    };

    if ($scope.params) {
      _.defaults(params, $scope.params);
    }

    return api.all({
      url: '/items',
      params: params
    });
  }
});
