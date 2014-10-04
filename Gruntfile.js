module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    copy: {
      assets: {
        files: [
          { nonull: true, src: 'bower_components/underscore/underscore.js', dest: 'vendor/assets/javascripts/underscore.js' },
          { nonull: true, src: 'bower_components/jquery/dist/jquery.js', dest: 'vendor/assets/javascripts/jquery.js' },
          { nonull: true, src: 'bower_components/angular/angular.js', dest: 'vendor/assets/javascripts/angular.js' },
          { nonull: true, src: 'bower_components/angular-ui-router/release/angular-ui-router.js', dest: 'vendor/assets/javascripts/angular-ui-router.js' },
          { nonull: true, src: 'bower_components/angular-bootstrap/ui-bootstrap.js', dest: 'vendor/assets/javascripts/angular-ui-bootstrap.js' },
          { nonull: true, src: 'bower_components/angular-bootstrap/ui-bootstrap-tpls.js', dest: 'vendor/assets/javascripts/angular-ui-bootstrap-tpls.js' },
          { nonull: true, src: 'bower_components/angular-cookies/angular-cookies.js', dest: 'vendor/assets/javascripts/angular-cookies.js' },
          { nonull: true, src: 'bower_components/angular-base64/angular-base64.js', dest: 'vendor/assets/javascripts/angular-base64.js' },
          { nonull: true, src: 'bower_components/angular-local-storage/angular-local-storage.js', dest: 'vendor/assets/javascripts/angular-local-storage.js' },
          { nonull: true, src: 'bower_components/angular-gravatar/build/md5.js', dest: 'vendor/assets/javascripts/md5.js' },
          { nonull: true, src: 'bower_components/angular-gravatar/build/angular-gravatar.js', dest: 'vendor/assets/javascripts/angular-gravatar.js' },
          { nonull: true, src: 'bower_components/ng-table/ng-table.js', dest: 'vendor/assets/javascripts/ng-table.js' },
          { nonull: true, src: 'bower_components/ngInfiniteScroll/build/ng-infinite-scroll.js', dest: 'vendor/assets/javascripts/angular-ng-infinite-scroll.js' },
          { nonull: true, src: 'bower_components/bootstrap/dist/js/bootstrap.js', dest: 'vendor/assets/javascripts/bootstrap.js' },
          { nonull: true, src: 'bower_components/normalize-css/normalize.css', dest: 'vendor/assets/stylesheets/normalize.css' },
          { nonull: true, src: 'bower_components/bootstrap-social/bootstrap-social.css', dest: 'vendor/assets/stylesheets/bootstrap-social.css' },
          { nonull: true, src: 'bower_components/ng-table/ng-table.css', dest: 'vendor/assets/stylesheets/ng-table.css' },
          { nonull: true, cwd: 'bower_components/font-awesome/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true },
          { nonull: true, cwd: 'bower_components/bootstrap/dist/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true }
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

  grunt.registerTask('default', ['jshint', 'karma:unitSingleRun']);
  grunt.registerTask('test', ['watch:test']);
  grunt.registerTask('vendor', ['copy:assets', 'copy:testAssets', 'copy:bootstrap', 'copy:bootstrapTheme', 'copy:fontawesome']);
};
