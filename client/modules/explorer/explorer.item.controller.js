angular.module('lair.explorer').controller('ExplorerItemCtrl', function(api, auth, explorer, items, languages, $log, $scope, $state, titles) {

  $scope.currentUser = auth.currentUser;
  auth.addAuthFunctions($scope);

  _.extend($scope, _.pick(items, 'humanItemRange', 'humanReleaseDate'));
  _.extend($scope, _.pick(titles, 'secondaryTitle', 'otherTitles'));
  $scope.humanItemLength = items.humanLength;

  fetchWork();
  fetchLanguages();

  $scope.edit = function(item) {
    explorer.close();
    $state.go('items.edit', {
      itemId: item.id
    });
  };

  $scope.showWork = function() {
    api({
      url: '/works/' + $scope.item.workId
    }).then(function(res) {
      explorer.open('works', res.data);
    });
  };

  $scope.formatIsbn = function(isbn) {
    return isbn ? ISBN.hyphenate(isbn) : '-';
  };

  $scope.formatRange = function(item, work) {
    if (!item || !work || !item.start) {
      return;
    }

    var rangeType;
    if (_.includes([ 'anime', 'show' ], work.category)) {
      rangeType = 'episode';
    } else if (_.includes([ 'book', 'manga' ], work.category)) {
      rangeType = 'volume';
    } else if (_.includes([ 'magazine' ], work.category)) {
      rangeType = 'issue';
    } else {
      return;
    }

    return inflection.inflect(rangeType, item.end - item.start + 1) + ' ' + items.humanItemRange(item);
  };

  $scope.$on('ownership', function(event, ownership, item) {
    // FIXME: move this to OwnDialogCtrl
    api({
      method: 'POST',
      url: '/ownerships',
      data: ownership
    }).then(function() {
      item.ownedByMe = true;
    }, function(err) {
      $log.warn('Could not create ownership for item ' + item.id);
      $log.debug(err);
    });
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

  function fetchWork() {
    api({
      url: '/works/' + $scope.item.workId
    }).then(function(res) {
      $scope.work = res.data;
    });
  }
});
