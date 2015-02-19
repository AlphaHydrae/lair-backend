angular.module('lair.items.edit', ['lair.forms', 'lair.images', 'ui.sortable'])

  .controller('EditItemController', ['ApiService', '$log', '$modal', '$scope', '$stateParams', function($api, $log, $modal, $scope, $stateParams) {

    var modal;

    $scope.selectImage = function() {
      $scope.imageSearchSubject = $scope.item;
      $scope.imageSearchResource = '/api/items/' + $scope.item.id + '/imageSearch';

      modal = $modal.open({
        controller: 'SelectImageCtrl',
        templateUrl: '/templates/selectImageDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(function(image) {
        $scope.editedItem.image = image;
      });
    };

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

    $scope.itemCategories = [ 'anime', 'book', 'manga', 'movie', 'show' ];
    $scope.relationshipRelations = [ 'author' ];

    $scope.titleSortOptions = {
      handle: '.move',
      cancel: '' // disable default jquery ui sortable behavior preventing elements of type ":input,button" to be used as handles
    };

    $api.http({
      url: '/api/items/' + $stateParams.itemId
    }).then(function(response) {
      $scope.item = parseItem(response.data);
      $scope.reset();
    });

    $api.http({
      url: '/api/languages'
    }).then(function(response) {
      $scope.languages = response.data;
    });

    $scope.relationshipPeople = [];

    $scope.fetchRelationshipPeople = function(relationship, index, search) {
      if (!search || !search.trim().length) {
        if ($scope.item.relationships[index]) {
          $scope.relationshipPeople[index] = _.compact([ $scope.item.relationships[index].person ]);
        } else {
          $scope.relationshipPeople[index] = [];
        }
        return;
      }

      $api.http({
        url: '/api/people',
        params: {
          pageSize: 100,
          search: search
        }
      }).then(function(res) {
        $scope.relationshipPeople[index] = res.data;
      }, function(res) {
        $log.warn('Could not fetch items matching "' + search + '"');
        $log.debug(res);
      });
    };

    $scope.save = function() {
      $api.http({
        method: 'PATCH',
        url: '/api/items/' + $stateParams.itemId,
        data: dumpItem($scope.editedItem)
      }).then(function(response) {
        $scope.item = parseItem(response.data);
        $scope.reset();
      }, function(response) {
        // TODO: handle error
        console.log('FAILED!');
        console.log(response);
      });
    };

    $scope.reset = function() {
      $scope.editedItem = angular.copy($scope.item);
      $scope.relationshipPeople = [];
    };

    $scope.itemChanged = function() {
      return !angular.equals($scope.item, $scope.editedItem);
    };

    $scope.addTitle = function() {
      $scope.editedItem.titles.push({});
    };

    $scope.removeTitle = function(title) {
      $scope.editedItem.titles.splice($scope.editedItem.titles.indexOf(title), 1);
    };

    $scope.addLink = function() {
      $scope.editedItem.links.push({});
    };

    $scope.removeLink = function(link) {
      $scope.editedItem.links.splice($scope.editedItem.links.indexOf(link), 1);
    };

    $scope.addRelationship = function() {
      $scope.editedItem.relationships.push({ relation: 'author' });
      $scope.relationshipPeople.push([]);
    };

    $scope.removeRelationship = function(relationship) {
      $scope.editedItem.relationships.splice($scope.editedItem.relationships.indexOf(relationship), 1);
    };

    $scope.addTag = function() {
      $scope.editedItem.tags.push({});
    };

    $scope.removeTag = function(tag) {
      $scope.editedItem.tags.splice($scope.editedItem.tags.indexOf(tag), 1);
    };
  }])

;
