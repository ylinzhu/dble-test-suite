# -*- coding=utf-8 -*-
# Copyright (C) 2016-2019 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
@setup
Feature: nosharding table sql cover test
"""
Given rm old logs "sql_cover_nosharding" if exists
Given reset replication and none system databases
Given reset views in "dble-1" if exists
"""

    Scenario Outline:sql cover for nosharding table #2
      Given set sql cover log dir "sql_cover_nosharding"
      Then execute sql in file "<filename>"
      Given clear dirty data yield by sql

      Examples:Types
        | filename                                              |
        | special_nosharding/select/join_no_sharding.sql        |
        | special_nosharding/select/reference_no_sharding.sql   |
        | special_nosharding/select/subquery_no_sharding.sql    |
        | special_nosharding/select/join_union_subquery_mixed.sql    |