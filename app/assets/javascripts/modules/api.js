angular.module('lair.api', ['lair.auth'])

  .service('ApiService', ['$http', function($http) {

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

    return {
      http: function(options) {
        return $http(options);
      },

      rateLimit: function(response) {

        var total = response.headers('X-RateLimit-Total'),
            remaining = response.headers('X-RateLimit-Remaining'),
            reset = response.headers('X-RateLimit-Reset');

        if (!total) {
          return null;
        }

        return new RateLimit(parseInt(total, 10), parseInt(remaining, 10), new Date(parseInt(reset, 10) * 1000));
      }
    };
  }])

;
