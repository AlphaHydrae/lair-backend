module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    copy: {
      assets: {
        files: [
          // Javascripts
          { nonull: true, src: 'bower_components/lodash/dist/lodash.js', dest: 'vendor/assets/javascripts/lodash.js' },
          { nonull: true, src: 'bower_components/jquery/dist/jquery.js', dest: 'vendor/assets/javascripts/jquery.js' },
          { nonull: true, src: 'bower_components/inflection/lib/inflection.js', dest: 'vendor/assets/javascripts/inflection.js' },
          { nonull: true, src: 'bower_components/jquery-ui/jquery-ui.js', dest: 'vendor/assets/javascripts/jquery-ui.js' },
          { nonull: true, src: 'bower_components/moment/moment.js', dest: 'vendor/assets/javascripts/moment.js' },
          { nonull: true, src: 'bower_components/pretty-bytes/pretty-bytes.js', dest: 'vendor/assets/javascripts/pretty-bytes.js' },
          { nonull: true, src: 'bower_components/angular/angular.js', dest: 'vendor/assets/javascripts/angular.js' },
          { nonull: true, src: 'bower_components/angular-sanitize/angular-sanitize.js', dest: 'vendor/assets/javascripts/angular-sanitize.js' },
          { nonull: true, src: 'bower_components/angular-ui-router/release/angular-ui-router.js', dest: 'vendor/assets/javascripts/angular-ui-router.js' },
          { nonull: true, src: 'bower_components/angular-bootstrap/ui-bootstrap-tpls.js', dest: 'vendor/assets/javascripts/angular-ui-bootstrap-tpls.js' },
          { nonull: true, src: 'bower_components/angular-base64/angular-base64.js', dest: 'vendor/assets/javascripts/angular-base64.js' },
          { nonull: true, src: 'bower_components/a0-angular-storage/dist/angular-storage.js', dest: 'vendor/assets/javascripts/angular-storage.js' },
          { nonull: true, src: 'bower_components/angular-gravatar/build/angular-gravatar.js', dest: 'vendor/assets/javascripts/angular-gravatar.js' },
          { nonull: true, src: 'bower_components/ngInfiniteScroll/build/ng-infinite-scroll.js', dest: 'vendor/assets/javascripts/angular-ng-infinite-scroll.js' },
          { nonull: true, src: 'bower_components/angular-ui-sortable/sortable.js', dest: 'vendor/assets/javascripts/angular-ui-sortable.js' },
          { nonull: true, src: 'bower_components/angular-ui-select/dist/select.js', dest: 'vendor/assets/javascripts/angular-ui-select.js' },
          { nonull: true, src: 'bower_components/angular-moment/angular-moment.js', dest: 'vendor/assets/javascripts/angular-moment.js' },
          { nonull: true, src: 'bower_components/angular-ui-date/dist/date.js', dest: 'vendor/assets/javascripts/angular-ui-date.js' },
          { nonull: true, src: 'bower_components/angular-smart-table/dist/smart-table.js', dest: 'vendor/assets/javascripts/angular-smart-table.js' },
          { nonull: true, src: 'bower_components/angular-pretty-bytes/angular-pretty-bytes.js', dest: 'vendor/assets/javascripts/angular-pretty-bytes.js' },
          { nonull: true, src: 'bower_components/ngInflection/dist/ngInflection.js', dest: 'vendor/assets/javascripts/angular-ng-inflection.js' },
          { nonull: true, src: 'bower_components/satellizer/dist/satellizer.js', dest: 'vendor/assets/javascripts/satellizer.js' },
          { nonull: true, src: 'bower_components/bootstrap/dist/js/bootstrap.js', dest: 'vendor/assets/javascripts/bootstrap.js' },
          // Stylesheets
          { nonull: true, src: 'bower_components/normalize-css/normalize.css', dest: 'vendor/assets/stylesheets/normalize.css' },
          { nonull: true, src: 'bower_components/bootstrap-social/bootstrap-social.css', dest: 'vendor/assets/stylesheets/bootstrap-social.css' },
          { nonull: true, src: 'bower_components/angular-ui-select/dist/select.css', dest: 'vendor/assets/stylesheets/angular-ui-select.css' },
          // Fonts
          { nonull: true, cwd: 'bower_components/font-awesome/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true },
          { nonull: true, cwd: 'bower_components/bootstrap/dist/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true },
          // Images
          { nonull: true, cwd: 'bower_components/jquery-ui/themes/smoothness/images/', src: '**', dest: 'vendor/assets/images/', flatten: true, expand: true }
        ],
        options: {
          process: removeSourceMaps
        }
      },

      binary: {
        files: [
          // Fonts
          { nonull: true, cwd: 'bower_components/font-awesome/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true },
          { nonull: true, cwd: 'bower_components/bootstrap/dist/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true },
          // Images
          { nonull: true, cwd: 'bower_components/jquery-ui/themes/smoothness/images/', src: '**', dest: 'vendor/assets/images/', flatten: true, expand: true }
        ]
      },

      testAssets: {
        files: [
          { nonull: true, src: 'bower_components/angular-mocks/angular-mocks.js', dest: 'spec/angular/support/angular-mocks.js' }
        ]
      },

      bootstrap: {
        src: 'bower_components/bootstrap/dist/css/bootstrap.css',
        dest: 'vendor/assets/stylesheets/bootstrap.css.less',
        options: {
          process: function(content) {
            return content.replace(/url\('\.\.\/fonts\//g, 'asset-url(\'').replace(/\/\*\#.*\*\//, '');
          }
        }
      },

      bootstrapTheme: {
        src: 'bower_components/bootstrap/dist/css/bootstrap-theme.css',
        dest: 'vendor/assets/stylesheets/bootstrap-theme.css',
        options: {
          process: function(content) {
            return content.replace(/\/\*\#.*\*\//, '');
          }
        }
      },

      fontawesome: {
        src: 'bower_components/font-awesome/css/font-awesome.css',
        dest: 'vendor/assets/stylesheets/font-awesome.css.less',
        options: {
          process: function(content) {
            return content.replace(/url\('\.\.\/fonts\//g, 'asset-url(\'');
          }
        }
      },

      jqueryUi: {
        src: 'bower_components/jquery-ui/themes/smoothness/jquery-ui.css',
        dest: 'vendor/assets/stylesheets/jquery-ui.css.less',
        options: {
          process: function(content) {
            return content.replace(/url\("images\//g, 'asset-url("');
          }
        }
      }
    },

    jshint: {
      all: ['*.js', 'app/assets/javascripts/**/*.js', 'spec/angular/**/*.js', '!spec/angular/support/angular-mocks.js']
    },

    karma: {
      unit: {
        configFile: 'spec/angular/karma.conf.js'
      },

      unitSingleRun: {
        configFile: 'spec/angular/karma.conf.js',
        singleRun: true
      }
    },

    watch: {
      jshint: {
        files: ['*.js', 'app/assets/javascripts/**/*.js', 'spec/angular/**/*.js', '!spec/angular/support/angular-mocks.js'],
        tasks: ['jshint']
      },

      test: {
        files: ['spec/angular/assets.json', 'spec/angular/lair.js'],
        tasks: ['karma:unit'],
        options: {
          atBegin: true,
          interrupt: true
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-karma');
  grunt.loadNpmTasks('grunt-contrib-watch');

  grunt.registerTask('default', [ 'jshint', 'karma:unitSingleRun' ]);
  grunt.registerTask('test', [ 'watch:test' ]);
  grunt.registerTask('vendor', [ 'copy:assets', 'copy:binary', 'copy:testAssets', 'copy:bootstrap', 'copy:bootstrapTheme', 'copy:fontawesome', 'copy:jqueryUi' ]);
};

function removeSourceMaps(content, path) {
  if (path.match(/\.(?:css|js)$/)) {
    return content
      .replace(/\/\/\#\s*sourceMappingURL=.*/, '')
      .replace(/\/\*\#\s*sourceMappingURL=.*\s*\*\//, '');
  } else {
    return content;
  }
}
