angular.module('lair.gallery').directive('galleryFilters', function() {
  return {
    restrict: 'E',
    controller: 'GalleryFiltersCtrl',
    templateUrl: '/templates/modules/gallery/gallery.filters.template.html',
    scope: {
      collection: '=',
      filtersData: '=',
      filtersAdvanced: '='
    }
  };
}).controller('GalleryFiltersCtrl', function(auth, $scope, users, works) {

  $scope.resourceChoices = [ 'works', 'items' ];

  // FIXME: keep data type choices up to date when user logs in/out
  // FIXME: disallow ownerships for default filters
  if (auth.currentUser) {
    $scope.resourceChoices.push('ownerships');
  }

  $scope.toggleAdvancedSearch = toggleAdvancedSearch;

  var categories,
      ownerIds;

  if ($scope.collection) {
    categories = $scope.collection.restrictions.categories;
    ownerIds = $scope.collection.restrictions.ownerIds;
  }

  $scope.$watch('collection.restrictions.categories', setCategoryChoices, true);
  $scope.$watch('collection.restrictions.ownerIds', setOwnerChoices, true);

  function setCategoryChoices(allowedCategories) {
    if (!allowedCategories) {
      $scope.categoryChoices = works.categories.slice();
    } else if (allowedCategories.length >= 2) {
      $scope.categoryChoices = _.filter(works.categories, function(category) {
        return _.includes(allowedCategories, category.name);
      });
    } else {
      $scope.categoryChoices = allowedCategories;
    }

    if ($scope.filtersData.categories) {
      $scope.filtersData.categories = _.filter($scope.filtersData.categories, function(category) {
        return _.includes(allowedCategories, category);
      });
    }
  }

  function setOwnerChoices(allowedOwnerIds) {
    if (!allowedOwnerIds) {
      users.fetchAllUsers().then(function(users) {
        $scope.ownerChoices = users;
      });
    } else if (allowedOwnerIds.length >= 2) {
      users.fetchUsersById(allowedOwnerIds).then(function(users) {
        $scope.ownerChoices = users;
      });
    } else {
      $scope.ownerChoices = allowedOwnerIds;
    }

    if ($scope.filtersData.ownerIds) {
      $scope.filtersData.ownerIds = _.filter($scope.filtersData.ownerIds, function(ownerId) {
        return _.includes(allowedOwnerIds, ownerId);
      });
    }
  }

  function toggleAdvancedSearch() {
    $scope.advancedSearchEnabled = !$scope.advancedSearchEnabled;
  }
});
