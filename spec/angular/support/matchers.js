beforeEach(function() {
  this.addMatchers({
    toBeError: function(message) {

      var actual = this.actual,
          typeMatches = actual instanceof Error,
          messageMatches = actual.message === message,
          matches = typeMatches && messageMatches;

      if (!matches) {
        this.message = function() {
          if (!typeMatches) {
            return 'Expected ' + actual + ' to be an error';
          } else {
            return 'Expected error message "' + actual.message + '" to equal "' + message + '"';
          }
        };
      }

      return matches;
    }
  });
});
