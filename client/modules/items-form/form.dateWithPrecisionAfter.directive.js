angular.module('lair.items.form').directive('dateWithPrecisionAfter', function() {

  var dateRegexp = /^\d+(-[01]\d(-[0123]\d)?)?$/;

  return {
    restrict: 'A',
    require: 'ngModel',
    link: function($scope, elm, attrs, ctrl) {
      ctrl.$validators.dateWithPrecisionAfter = function(modelValue, viewValue) {
        if (!modelValue || !modelValue.length) {
          return true;
        }

        var releaseDate = modelValue,
            referenceDate = $scope.$eval(attrs.dateWithPrecisionAfter);

        if (!releaseDate.match(dateRegexp) || !referenceDate.match(dateRegexp)) {
          return true;
        }

        var precisions = [ 'y', 'm', 'd' ],
            lowestPrecision = precisions[Math.min(precisions.indexOf(precision(releaseDate)), precisions.indexOf(precision(referenceDate)))];

        var normalizedReleaseDate = dateToPrecision(dateWithPrecision(releaseDate), lowestPrecision),
            normalizedReferenceDate = dateToPrecision(dateWithPrecision(referenceDate), lowestPrecision);

        return normalizedReleaseDate >= normalizedReferenceDate;
      };
    }
  };

  function dateWithPrecision(string) {
    var datePrecision = precision(string);
    if (datePrecision == 'y') {
      return new Date(string + '-01-01');
    } else if (datePrecision == 'm') {
      return new Date(string + '-01');
    } else {
      return new Date(string);
    }
  }

  function dateToPrecision(date, precision) {
    if (precision == 'y') {
      return new Date(date.getFullYear() + '-01-01');
    } else if (precision == 'm') {
      var month = date.getMonth() + 1;
      return new Date(date.getFullYear() + '-' + (month < 10 ? '0' + month : month) + '-01');
    } else {
      return date;
    }
  }

  function precision(date) {
    if (date.match(/^\d+$/)) {
      return 'y';
    } else if (date.match(/^\d+-\d+$/)) {
      return 'm';
    } else {
      return 'd';
    }
  }
});
