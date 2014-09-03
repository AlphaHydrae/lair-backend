module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    jshint: {
      all: ['*.js', 'app/assets/javascripts/**/*.js']
    },

    copy: {
      assets: {
        files: [
          { src: 'bower_components/underscore/underscore.js', dest: 'vendor/assets/javascripts/underscore.js' },
          { src: 'bower_components/jquery/dist/jquery.js', dest: 'vendor/assets/javascripts/jquery.js' },
          { src: 'bower_components/angular/angular.js', dest: 'vendor/assets/javascripts/angular.js' },
          { src: 'bower_components/angular-ui-router/release/angular-ui-router.js', dest: 'vendor/assets/javascripts/angular-ui-router.js' },
          { src: 'bower_components/angular-bootstrap/ui-bootstrap.js', dest: 'vendor/assets/javascripts/angular-ui-bootstrap.js' },
          { src: 'bower_components/angular-bootstrap/ui-bootstrap-tpls.js', dest: 'vendor/assets/javascripts/angular-ui-bootstrap-tpls.js' },
          { src: 'bower_components/angular-cookies/angular-cookies.js', dest: 'vendor/assets/javascripts/angular-cookies.js' },
          { src: 'bower_components/angular-base64/angular-base64.js', dest: 'vendor/assets/javascripts/angular-base64.js' },
          { src: 'bower_components/angular-local-storage/angular-local-storage.js', dest: 'vendor/assets/javascripts/angular-local-storage.js' },
          { src: 'bower_components/angular-gravatar/build/md5.js', dest: 'vendor/assets/javascripts/md5.js' },
          { src: 'bower_components/angular-gravatar/build/angular-gravatar.js', dest: 'vendor/assets/javascripts/angular-gravatar.js' },
          { src: 'bower_components/bootstrap/dist/js/bootstrap.js', dest: 'vendor/assets/javascripts/bootstrap.js' },
          { src: 'bower_components/normalize-css/normalize.css', dest: 'vendor/assets/stylesheets/normalize.css' },
          { src: 'bower_components/bootstrap-social/bootstrap-social.css', dest: 'vendor/assets/stylesheets/bootstrap-social.css' },
          { cwd: 'bower_components/font-awesome/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true },
          { cwd: 'bower_components/bootstrap/dist/fonts/', src: '**', dest: 'vendor/assets/fonts/', flatten: true, expand: true }
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
    }
  });

  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-jshint');

  grunt.registerTask('default', ['jshint']);
  grunt.registerTask('vendor', ['copy:assets', 'copy:bootstrap', 'copy:bootstrapTheme', 'copy:fontawesome']);
};
