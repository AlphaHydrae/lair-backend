angular.module('lair.api').factory('apiPagination', function($log) {

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
    this.start = parsePaginationHeader(response, 'X-Pagination-Start', true);
    this.number = parsePaginationHeader(response, 'X-Pagination-Number', true);
    this.end = this.start + this.number;
    this.grandTotal = parsePaginationHeader(response, 'X-Pagination-Total', true);
    this.filteredTotal = parsePaginationHeader(response, 'X-Pagination-Filtered-Total', false);
    this.total = this.filteredTotal || this.filteredTotal === 0 ? this.filteredTotal : this.grandTotal;
    this.length = response.data.length;
    this.percentage = (this.start + response.data.length) * 100 / this.total;

    this.filtered = (this.filteredTotal || this.filteredTotal === 0) && this.filteredTotal != this.grandTotal;
    this.numberOfPages = this.total === 0 ? 0 : Math.ceil(this.total / this.number);
  }

  Pagination.prototype.hasMorePages = function() {
    return this.total > this.start + this.number && this.length >= 1;
  };

  return function(res) {
    return function() {
      if (!res._pagination) {
        // otherwise, parse the pagination data
        res._pagination = new Pagination(res);
        $log.debug('api ' + res.n + ' pagination: ' + JSON.stringify(res._pagination));
      }

      return res._pagination;
    };
  };
});
