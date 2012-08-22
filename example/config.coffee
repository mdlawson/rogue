exports.config =
  # See http://brunch.readthedocs.org/en/latest/config.html for documentation.
  paths:
    public: './built'
    #vendor: '../lib'
  files:
    javascripts:
      joinTo:
        'js/app.js': /^app/
        'js/vendor.js': /^vendor/

    stylesheets:
      joinTo:
        'style/app.css': /^(app|vendor)/
  server:
    run: true