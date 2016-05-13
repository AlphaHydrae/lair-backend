angular.module('lair.works.edit').controller('EditWorkCtrl', function(api, $log, $scope, $state, $stateParams) {

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

  $scope.imageSearchResource = 'works';
  $scope.imageSearchResourceId = $stateParams.workId;

  api({
    url: '/works/' + $stateParams.workId
  }).then(function(response) {
    $scope.work = parseWork(response.data);
    reset();
    $scope.$broadcast('work', $scope.work);
  });

  $scope.save = function() {
    api({
      method: 'PATCH',
      url: '/works/' + $stateParams.workId,
      data: dumpWork($scope.modifiedWork)
    }).then(function(response) {
      $scope.work = parseWork(response.data);
      reset();
      $scope.$broadcast('work', $scope.work);
    }, function(response) {
      $log.warn('Could not update work ' + $stateParams.workId);
      $log.debug(response);
    });
  };

  $scope.reset = reset;

  function reset() {
    $scope.modifiedWork = angular.copy($scope.work);
    $scope.$broadcast('work', $scope.work);
  }

  $scope.cancel = function() {
    // TODO: go back
    $state.go('home');
  };

  $scope.destroy = function(event) {

    var hard = !!event.shiftKey;

    var message = 'Are you sure you want to';
    message += (hard ? ' HARD DELETE' : ' delete');
    message += ' ' + $scope.work.titles[0].text + '?';

    if (!confirm(message)) {
      return;
    }

    var params = {};
    if (hard) {
      params.hard = 1;
    }

    api({
      method: 'DELETE',
      url: '/works/' + $scope.work.id,
      params: params
    }).then(function() {
      $state.go('home');
    });
  };
});
