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

   Scenario:cover empty line in file, no line in file, chinese character in file, special character in file for sql syntax: load data [local] infile ...#1
     Given set sql cover log dir "sql_cover_nosharding"
     Given prepare loaddata.sql data for sql test
     Then execute sql in file "sqls_util/syntax/loaddata.sql"
     Given clear dirty data yield by sql
     Given clean loaddata.sql used data

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

    Scenario: #5 compare new generated results is same with the standard ones
        When compare results in "sql_cover_nosharding" with the standard results in "std_sql_cover_nosharding"