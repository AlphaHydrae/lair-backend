angular.module('lair.items').factory('items', function(languages, $q) {

  var service = {
    types: [ 'volume', 'issue', 'video' ],

    typesForWork: function(work) {
      if (_.includes([ 'book', 'manga' ], work.category)) {
        return [ 'volume' ];
      } else if (_.includes([ 'magazine' ], work.category)) {
        return [ 'issue' ];
      } else if (_.includes([ 'anime', 'movie', 'show' ], work.category)) {
        return [ 'video' ];
      }
    },

    groupItems: function(items) {
      return languages.loadLanguageNamesByTag().then(function(languageNamesByTag) {
        return groupItems(items, languageNamesByTag);
      });
    },

    orderItems: function(items) {
      return $q.when(_.sortBy(items, function(item) {
        return (item.special ? 'S' : 'A') + _.padStart('' + item.start, 10, '0');
      }));
    },

    humanItemRange: function(item) {
      if (!item || item.start === undefined) {
        return;
      }

      var range = '' + item.start;
      if (item.end != item.start) {
        range += '-' + item.end;
      }

      return range;
    },

    humanReleaseDate: function(date) {
      if (!date) {
        return;
      }

      return humanDateWithPrecision(date);
    },

    humanMainReleaseDate: function(item) {
      if (!item) {
        return;
      }

      var date = item.releaseDate || item.originalReleaseDate;
      if (!date) {
        return '-';
      }

      return humanDateWithPrecision(date);
    },

    humanSecondaryReleaseDate: function(item) {
      if (!item || !item.releaseDate || !item.originalReleaseDate) {
        return;
      }

      return humanDateWithPrecision(item.originalReleaseDate);
    },

    humanLength: function(item) {
      if (!item.length) {
        return '-';
      }

      if (item.type == 'book' || item.type == 'issue') {
        return item.length + ' ' + inflection.inflect('page', item.length);
      } else if (item.type == 'video') {
        if (item.length < 60) {
          return item.length + ' min';
        } else {

          var hours = Math.floor(item.length / 60),
              minutes = item.length - 60 * hours;

          var result = hours + ' ' + inflection.inflect('hour', hours);
          if (minutes) {
            result += ' ' + minutes + ' min';
          }

          return result;
        }
      } else {
        return '' + item.length;
      }

      return;
    }
  };

  function humanDateWithPrecision(date) {
    if (!date) {
      return '-';
    } else if (date.match(/^\d{4}$/)) {
      return date;
    } else if (date.match(/^\d{4}-\d{2}$/)) {
      return moment(date + '-01').format('MMM YYYY');
    } else if (date.match(/^\d{4}-\d{2}-\d{2}$/)) {
      return moment(date).format('ll');
    } else {
      return '-';
    }
  }

  function groupItems(items, languageNamesByTag) {

    var groups = [];

    _.each(items, function(item) {

      var groupNameParts = [ languageNamesByTag[item.language] ];

      if (item.edition) {
        groupNameParts.push(item.edition + ' Edition');
      }

      if (item.publisher) {
        groupNameParts.push('(' + item.publisher + ')');
      }

      var groupName = _.compact(groupNameParts).join(' ');
      groupName = groupName.length ? groupName : 'Other';

      var group = _.find(groups, { name: groupName });
      if (!group) {
        group = { name: groupName, items: [] };
        groups.push(group);
      }

      group.items.push(item);
    });

    return groups;
  }

  return service;
});
