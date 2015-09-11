'use strict';

/* Controllers */

var controllers = angular.module('ebiscProgress.controllers', []);

controllers.controller('LineListCtrl', ['List', function(List) {
    var controller = this;
    this.data = List.query({name: 'api_compares'});
    this.data.$promise.then(function(data) {
      controller.data = data;
    });

    this.sortColumn = 'name';
    this.sortDesc = false;
    this.sortBy = function(column) {
      this.data.lines.sort(
        column === 'IMSExported' ? function(a,b) {return b.IMS.exported.error - a.IMS.exported.error || a.consensus.name.error - b.consensus.name.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'hESCregExported' ? function(a,b) {return b.hESCreg.exported.error - a.hESCreg.exported.error || a.consensus.name.error - b.consensus.name.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'hESCregValidated' ? function(a,b) {return b.hESCreg.validated.error - a.hESCreg.validated.error || a.hESCreg.exported.error - b.hESCreg.exported.error || a.consensus.name.error - b.consensus.name.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'biosampleExported' ? function(a,b) {return b.biosample.exported.error - a.biosample.exported.error || a.consensus.name.error - b.consensus.name.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'alternateNames' ? function(a,b) {return a.consensus.alternate_names.localeCompare(b.consensus.alternate_names) || a.consensus.name.error - b.consensus.name.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'IMSOther' ? function(a,b) {return (!a.IMS.exported.error && !b.IMS.exported.error) ? (b.IMS.name.error - a.IMS.name.error || b.IMS.biosample_id.error - a.IMS.biosample_id.error || b.IMS.donor_biosample_id.error - a.IMS.donor_biosample_id.error || a.consensus.name.val.localeCompare(b.consensus.name.val)) : a.IMS.exported.error - b.IMS.exported.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'hESCregOther' ? function(a,b) {return (!a.hESCreg.exported.error && !b.hESCreg.exported.error) ? (b.hESCreg.name.error - a.hESCreg.name.error || b.hESCreg.biosample_id.error - a.hESCreg.biosample_id.error || b.hESCreg.donor_biosample_id.error - a.hESCreg.donor_biosample_id.error || a.consensus.name.val.localeCompare(b.consensus.name.val)) : a.hESCreg.exported.error - b.hESCreg.exported.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : column === 'biosampleOther' ? function(a,b) {return b.donor_biosample.exported.error - a.donor_biosample.exported.error || b.biosample.batch_line_link.error - a.biosample.batch_line_link.error || b.biosample.batch_donor_link.error - a.biosample.batch_donor_link.error || b.biosample.id.error - a.biosample.id.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
          : function(a,b) {return a.consensus.name.error - b.consensus.name.error || a.consensus.name.val.localeCompare(b.consensus.name.val)}
      );
      if (column === this.sortColumn) {
        this.sortDesc = !this.sortDesc;
        if (this.sortDesc) {
          this.data.lines.reverse();
        }
      }
      else {
        this.sortDesc = false;
      }
      this.sortColumn = column;
    };

}]);

controllers.controller('LineDetailCtrl', ['List', '$routeParams', function(List, $routeParams) {
    var controller = this;
    this.searchName = $routeParams.line;
    this.error = 0;
    this.lines = [];
    List.query({name: 'api_compares'}).$promise.then(function(data) {
      for (var i=0; i<data.lines.length; i++) {
        if (data.lines[i].IMS.name.val === controller.searchName
          || data.lines[i].IMS.biosample_id.val === controller.searchName
          || data.lines[i].hESCreg.name.val === controller.searchName
          || data.lines[i].hESCreg.biosample_id.val === controller.searchName
          || data.lines[i].biosample.id.val === controller.searchName
          || data.lines[i].biosample.name === controller.searchName) {
          controller.lines.push(data.lines[i]);
        }
      }
      if (controller.lines.length == 0) {
        controller.error = 1;
      }
    });

}]);

controllers.controller('ErrorListCtrl', ['List', function(List) {
    var controller = this;
    this.errors = List.query({name: 'errors'});
    this.errors.$promise.then(function(data) {
      controller.errors = data.errors;
    });

}]);

controllers.controller('TestListCtrl', ['List', function(List) {
    var controller = this;
    this.tests = [];
    this.tests_totalled = {};
    List.query({name: 'tests'}).$promise.then(function(data) {
      controller.tests = data.tests;
      controller.tests_totalled = data.tests_totalled;
    });

}]);

