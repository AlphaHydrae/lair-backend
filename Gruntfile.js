module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    jshint: {
      all: ['*.js', 'app/assets/javascripts/**/*.js']
    },

    copy: {
      fonts: {
        files: [
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
  grunt.registerTask('assets', ['copy:fonts', 'copy:bootstrap', 'copy:fontawesome']);
};
