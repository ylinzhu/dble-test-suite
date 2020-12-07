# Copyright (C) 2016-2019 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
# Created by quexiuping at 2020/12/07

Feature: test mysql_Large_package_protocol
  1.Large_package 16M,16M-1,16M-2,16M+1,16M+2
  2.Large_package 32M,32M-1,32M-2,32M+1,32M+2
  3.insert/select/update/delete

  Scenario: Large_package 16M,16M-1,16M-2,16M+1,16M+2 and       #1
    