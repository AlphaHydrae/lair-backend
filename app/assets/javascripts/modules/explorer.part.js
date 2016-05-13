angular.module('lair.explorer.part', [ 'lair.api', 'lair.auth' ])

  .directive('explorerPart', function() {
    return {
      templateUrl: '/templates/explorer-part.html',
      controller: 'ExplorerPartCtrl',
      scope: {
        part: '=',
        params: '='
      }
    };
  })

  .controller('ExplorerPartCtrl', function(api, auth, explorer, $log, $scope, $state) {

    $scope.currentUser = auth.currentUser;
    auth.addAuthFunctions($scope);

    $scope.edit = function(part) {
      explorer.close();
      $state.go('parts.edit', {
        partId: part.id
      });
    };

    $scope.showItem = function() {
      api({
        url: '/items/' + $scope.part.itemId
      }).then(function(res) {
        explorer.open('items', res.data);
      });
    };

    $scope.formatIsbn = function(isbn) {
      return isbn ? ISBN.hyphenate(isbn) : '-';
    };

    $scope.$on('ownership', function(event, ownership, part) {
      // FIXME: move this to OwnDialogCtrl
      api({
        method: 'POST',
        url: '/ownerships',
        data: ownership
      }).then(function() {
        part.ownedByMe = true;
      }, function(err) {
        $log.warn('Could not create ownership for part ' + part.id);
        $log.debug(err);
      });
    });
  })

  .controller('YieldDialogCtrl', function(api, auth, $scope) {

    $scope.dateOptions = {
      dateFormat: 'yy-mm-dd',
      maxDate: new Date()
    };

    $scope.$watch('ownership', function(value) {
      if (value && !value.yieldedAt) {
        value.yieldedAt = new Date();
        $scope.dateOptions.minDate = moment(value.gottenAt).toDate();
      }
    });

    api({
      url: '/ownerships',
      params: {
        partId: $scope.part.id,
        userId: auth.currentUser.id,
        owned: true
      }
    }).then(function(res) {
      $scope.ownerships = res.data;

      if (res.data.length) {
        $scope.ownership = res.data[0];
      }
    });

    $scope.yield = function() {

      $scope.saved = false;

      api({
        method: 'PATCH',
        url: '/ownerships/' + $scope.ownership.id,
        data: {
          yieldedAt: moment($scope.ownership.yieldedAt).toISOString()
        }
      }).then(function(res) {
        $scope.saved = true;
      });
    };
  })

  .controller('OwnDialogCtrl', function($scope) {

    $scope.dateOptions = {
      dateFormat: 'yy-mm-dd'
    };

    $scope.ownership = {
      partId: $scope.part.id,
      gottenAt: new Date()
    };

    $scope.create = function() {
      $scope.$emit('ownership', $scope.ownership, $scope.part);
    };
  })

  .directive('ownDialog', function ($compile) {
    return function(scope, element, attrs) {

      var shown = false,
          contentTemplate = _.template('<form ng-controller="OwnDialogCtrl" ng-submit="create()" class="ownDialog"><div class="form-group"><label>Owned since</label><input class="form-control" ui-date="dateOptions" ng-model="ownership.gottenAt" /></div><button type="submit" class="btn btn-primary btn-block">Add</button></form>');

      element.on('mouseenter', function() {
        if (!shown) {
          element.tooltip('show');
        }
      });

      element.on('mouseleave', function() {
        element.tooltip('hide');
      });

      scope.$on('ownership', function() {
        element.popover('hide');
        shown = false;
      });

      element.on('click', function() {
        element.popover(shown ? 'hide' : 'show');
        element.tooltip(shown ? 'show' : 'hide');
        shown = !shown;
      });

      element.tooltip({
        trigger: 'manual',
        title: 'I own this'
      });

      element.popover({
        trigger: 'manual',
        placement: 'auto',
        content: $compile(contentTemplate({}))(scope),
        html: true,
        template: '<div class="popover ownDialogPopover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
      });
    };
  })

;
