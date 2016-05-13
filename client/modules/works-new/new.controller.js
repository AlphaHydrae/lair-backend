angular.module('lair.works.new').controller('NewWorkCtrl', function(api, $log, $scope, $state, $stateParams) {

  function parseWork(work) {
    return _.extend({}, work, {
      properties: _.reduce(_.keys(work.properties).sort(), function(memo, key) {
        memo.push({ key: key, value: work.properties[key] });
        return memo;
      }, [])
    });
  }

  function dumpWork(work) {
    return _.extend({}, work, {
      properties: _.reduce(work.properties, function(memo, property) {
        memo[property.key] = property.value;
        return memo;
      }, {})
    });
  }

  $scope.work = parseWork({
    category: 'manga',
    titles: [ {} ],
    relationships: [],
    links: [],
    properties: []
  });

  $scope.modifiedWork = angular.copy($scope.work);
  $scope.$broadcast('work', $scope.work);

  $scope.save = function() {
    save().then(edit);
  };

  $scope.saveAndAddItem = function() {
    save().then(addItem);
  };

  function save() {
    return api({
      method: 'POST',
      url: '/works',
      data: dumpWork($scope.modifiedWork)
    }).then(function(res) {
      return res.data;
    }, function(response) {
      $log.warn('Could not create work');
      $log.debug(response);
    });
  }

  function edit(work) {
    $state.go('works.edit', { workId: work.id });
  }

  function addItem(work) {
    $state.go('items.new', { workId: work.id });
  }

  $scope.cancel = function() {
    $state.go('home');
  };
});
