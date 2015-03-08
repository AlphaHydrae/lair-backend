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

    function parsePaginationHeader(response, header, required) {

      var value = response.headers(header);
      if (!value) {
        if (required) {
          throw new Error('Exected response to have the ' + header + ' header');
        } else {
          return null;
        }
      }

      var number = parseInt(value, 10);
      if (isNaN(number)) {
        throw new Error('Expected response header ' + header + ' to contain an integer, got "' + value + '" (' + typeof(value) + ')');
      }

      return number;
    }

    function Pagination(response) {
      this.page = parsePaginationHeader(response, 'X-Pagination-Page', true);
      this.pageSize = parsePaginationHeader(response, 'X-Pagination-PageSize', true);
      this.total = parsePaginationHeader(response, 'X-Pagination-Total', true);
      this.filteredTotal = parsePaginationHeader(response, 'X-Pagination-FilteredTotal', false);
      this.startNumber = (this.page - 1) * this.pageSize + 1;
      this.endNumber = this.page * this.pageSize;
      this.numberOfPages = Math.ceil((this.filteredTotal || this.total) / this.pageSize);
    }

    Pagination.hasPagination = function(response) {
      return !!response.headers('X-Pagination-Total');
    };

    Pagination.prototype.hasMorePages = function() {
      return this.page * this.pageSize < (this.filteredTotal !== undefined ? this.filteredTotal : this.total);
    };

    return {
      http: function(options) {
        // TODO: automatically prepend /api to path
        return $http(options).then(function(res) {

          // enrich response with pagination function
          res.pagination = function() {

            if (!Pagination.hasPagination(res)) {
              // throw an error if no pagination data is available
              throw new Error('Expected response to have pagination headers');
            } else if (!res.paginationData) {
              // otherwise, parse the pagination data
              res.paginationData = new Pagination(res);
            }

            return res.paginationData;
          };

          return res;
        });
      },

      // TODO: add as utility function on response (like pagination)
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
