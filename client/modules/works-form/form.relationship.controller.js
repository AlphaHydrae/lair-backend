angular.module('lair.works.form').controller('WorkRelationshipCtrl', function(api, works, $log, $modal, $scope) {

  $scope.matchingPeople = [];
  $scope.matchingCompanies = [];

  $scope.fetchPeople = resourceFetcher('people');
  $scope.fetchCompanies = resourceFetcher('companies');

  $scope.$watch('relationship.relation', function(value) {
    if (value) {
      $scope.resource = works.relationResource(value);
    }
  });

  $scope.$watch('relationship.companyId', function(newValue) {
    if (newValue === -1) {
      createNewResource('companies');
    }
  });

  $scope.$watch('relationship.personId', function(newValue) {
    if (newValue === -1) {
      createNewResource('people');
    }
  });

  $scope.remove = function() {
    if ($scope.onRemove) {
      $scope.onRemove();
    }
  };

  function createNewResource(resource) {

    var singularName = inflection.singularize(resource),
        controller = 'New' + inflection.capitalize(singularName) + 'Ctrl',
        templateUrl = '/templates/modules/works-form/form.new' + inflection.capitalize(singularName) + 'Dialog.template.html',
        matchingVar = 'matching' + inflection.capitalize(resource),
        idVar = singularName + 'Id';

    var modal = $modal.open({
      controller: controller,
      templateUrl: templateUrl,
      scope: $scope
    });

    modal.result.then(function(resource) {
      $scope[matchingVar].push(resource);
      $scope.relationship[idVar] = resource.id;
    }, function() {
      delete $scope.relationship[idVar];
    });
  }

  function resourceFetcher(resource) {

    var association = inflection.singularize(resource),
        matchingVar = 'matching' + inflection.capitalize(resource);

    return function(search) {
      if (!search || !search.trim().length) {
        if ($scope.relationship[association]) {
          $scope[matchingVar] = _.compact([ $scope.relationship[association] ]);
        } else {
          $scope[matchingVar] = [];
        }

        return;
      }

      api({
        url: '/' + resource,
        params: {
          number: 100,
          search: search
        }
      }).then(function(res) {
        $scope[matchingVar] = res.data;
        $scope[matchingVar].unshift({ id: -1 });
      }, function(res) {
        $log.warn('Could not fetch ' + resource + ' matching "' + search + '"');
        $log.debug(res);
      });
    };
  }
});
