angular.module('lair.api').factory('apiRateLimit', function() {

  function RateLimit(total, remaining, reset) {
    this.total = total;
    this.remaining = remaining;
    this.reset = reset;
    this.resetIn = reset.getTime() - new Date().getTime();
  }

  RateLimit.prototype.isExceeded = function() {
    return this.remaining <= 0 && new Date() <= this.reset;
  };

  RateLimit.prototype.clear = function() {
    this.remaining = this.total;
  };

  return function(res) {
    return function() {

      var total = res.headers('X-RateLimit-Total'),
          remaining = res.headers('X-RateLimit-Remaining'),
          reset = res.headers('X-RateLimit-Reset');

      if (!total) {
        return null;
      }

      return new RateLimit(parseInt(total, 10), parseInt(remaining, 10), new Date(parseInt(reset, 10) * 1000));
    };
  };
});
