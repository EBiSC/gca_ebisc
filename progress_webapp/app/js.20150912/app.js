'use strict';

var dependencies = [
  'ngRoute',
  'ngSanitize',
  'ebiscProgress.controllers',
  'ebiscProgress.services',
  'ui.bootstrap',
];

// Declare app level module which depends on filters, and services
var ebiscProgress = angular.module('ebiscProgress', dependencies);

ebiscProgress.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider.
    when('/', {
      templateUrl: 'partials.20150912/line-list.html',
      controller: 'LineListCtrl',
      controllerAs: 'LineCtrl',
    }).
    when('/errors', {
      templateUrl: 'partials.20150912/errors.html',
      controller: 'ErrorListCtrl',
      controllerAs: 'ErrorCtrl',
    }).
    when('/tests', {
      templateUrl: 'partials.20150912/tests.html',
      controller: 'TestListCtrl',
      controllerAs: 'TestCtrl',
    }).
    when('/:line', {
      templateUrl: 'partials.20150912/line-detail.html',
      controller: 'LineDetailCtrl',
      controllerAs: 'LineCtrl',
    }).
    otherwise({
      redirectTo: '/'
    });
  }
]);
