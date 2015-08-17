'use strict';

var services = angular.module('ebiscProgress.services', ['ngResource']);

services.factory('List', ['$resource',
  function($resource) {
    return $resource('json/:name.json', {}, {
      query: {
        method: 'GET',
        params: {
          name: 'api_compares'
        },
        isArray: false
      }
    });
  }
]);
