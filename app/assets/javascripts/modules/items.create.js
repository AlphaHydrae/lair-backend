angular.module('lair.items.create', ['lair.items.form'])

  .controller('CreateItemCtrl', function(api, $log, $scope, $state, $stateParams) {

    function parseItem(item) {
      return _.extend({}, item, {
        tags: _.reduce(_.keys(item.tags).sort(), function(memo, key) {
          memo.push({ key: key, value: item.tags[key] });
          return memo;
        }, [])
      });
    }

    function dumpItem(item) {
      return _.extend({}, item, {
        tags: _.reduce(item.tags, function(memo, tag) {
          memo[tag.key] = tag.value;
          return memo;
        }, {})
      });
    }

    $scope.item = parseItem({
      category: 'manga',
      titles: [ {} ],
      relationships: [],
      links: [],
      tags: []
    });

    $scope.imageSearchesResource = '/image-searches';

    $scope.modifiedItem = angular.copy($scope.item);
    $scope.$broadcast('item', $scope.item);

    $scope.save = function() {
      save().then(edit);
    };

    $scope.saveAndAddPart = function() {
      save().then(addPart);
    };

    function save() {
      return api({
        method: 'POST',
        url: '/items',
        data: dumpItem($scope.modifiedItem)
      }).then(function(res) {
        return res.data;
      }, function(response) {
        $log.warn('Could not create item');
        $log.debug(response);
      });
    }

    function edit(item) {
      $state.go('items.edit', { itemId: item.id });
    }

    function addPart(item) {
      $state.go('parts.create', { itemId: item.id });
    }

    $scope.cancel = function() {
      $state.go('home');
    };
  })

;
