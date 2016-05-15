angular.module('lair.titles').factory('titles', function() {

  var service = {
    secondaryTitle: function(record) {
      if (!record || !_.isArray(record.titles) || record.titles.length <= 1) {
        return;
      }

      var originalTitle = record.titles[0],
          englishTitle = _.find(record.titles, { language: 'en' });

      if (!englishTitle || englishTitle == originalTitle) {
        return;
      }

      return englishTitle.text;
    },

    otherTitles: function(record) {
      if (!record || !_.isArray(record.titles) || record.titles.length <= 1) {
        return;
      }

      var originalTitleText = record.titles[0].text,
          secondaryTitleText = service.secondaryTitle(record);

      return _.filter(record.titles, function(title) {
        return title.text != originalTitleText && title.text != secondaryTitleText;
      });
    }
  };

  return service;
});
