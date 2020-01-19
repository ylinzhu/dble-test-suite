# -*- coding=utf-8 -*-
# Copyright (C) 2016-2019 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
# Created by yangxiaoliang at 2020/1/19

Feature: Close the connection at different ddl stages

  Scenario: close the connection at first stage: verify connectivity of backend connections #1
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                                                                                               | expect  | db      |
      | test | 111111 | conn_0 | True    | drop table if exists test_shard                                                                   | success | schema1 |
      | test | 111111 | conn_0 | True    | create table test_shard(id int(11) NOT NULL,c_flag char(255),c_decimal decimal(16,4))CHARSET=utf8 | success | schema1 |
    Given prepare a thread run btrace script "SleepWhenAddMetaLock.java" in "dble-1"
    Given execute sqls in "dble-1" at background
      | user | passwd | conn   | toClose | sql                       | db      |
      | test | 111111 | conn_0 | True    | truncate table test_shard | schema1 |
    Then check btrace "SleepWhenAddMetaLock.java" output in "dble-1"
    """
    get into addMetaLock,start sleep
    """
    Given kill mysql query in "dble-1" forcely
    """
    truncate table test_shard
    """
    Then check btrace "SleepWhenAddMetaLock.java" output in "dble-1"
    """
    sleep end
    """
    Given stop btrace script "SleepWhenAddMetaLock.java" in "dble-1"
    Given destroy btrace threads list
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                       | expect  | db      |
      | test | 111111 | conn_0 | True    | truncate table test_shard | success | schema1 |
    Given delete file "/opt/dble/SleepWhenAddMetaLock.java" on "dble-1"
    Given delete file "/opt/dble/SleepWhenAddMetaLock.java.log" on "dble-1"

  Scenario: close the connection at second stage: some nodes finished ddl and some nodes not #2
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                                                                                               | expect  | db      |
      | test | 111111 | conn_0 | True    | drop table if exists test_shard                                                                   | success | schema1 |
      | test | 111111 | conn_0 | True    | create table test_shard(id int(11) NOT NULL,c_flag char(255),c_decimal decimal(16,4))CHARSET=utf8 | success | schema1 |
    Given prepare a thread run btrace script "SleepWhenClearIfSessionClosed.java" in "dble-1"
    Given execute sqls in "dble-1" at background
      | user | passwd | conn   | toClose | sql                                | db      |
      | test | 111111 | conn_0 | True    | alter table test_shard drop c_flag | schema1 |
    Then check btrace "SleepWhenClearIfSessionClosed.java" output in "dble-1" with "2" times
    """
    get into clearIfSessionClosed,start sleep
    """
    Given kill mysql query in "dble-1" forcely
    """
    alter table test_shard drop c_flag
    """
    Then check btrace "SleepWhenClearIfSessionClosed.java" output in "dble-1" with "2" times
    """
    sleep end
    """
    Given stop btrace script "SleepWhenClearIfSessionClosed.java" in "dble-1"
    Given destroy btrace threads list
    Then execute sql in "mysql-master1"
      | user | passwd | conn   | toClose | sql             | expect                                                                                               | db  |
      | test | 111111 | conn_0 | True    | desc test_shard | hasStr{(('id', 'int(11)', 'NO', '', None, ''), ('c_decimal', 'decimal(16,4)', 'YES', '', None, ''))} | db1 |
    Then execute sql in "mysql-master2"
      | user | passwd | conn   | toClose | sql             | expect                                                                                               | db  |
      | test | 111111 | conn_0 | True    | desc test_shard | hasStr{(('id', 'int(11)', 'NO', '', None, ''), ('c_decimal', 'decimal(16,4)', 'YES', '', None, ''))} | db1 |
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                       | expect  | db      |
      | test | 111111 | conn_0 | True    | truncate table test_shard | success | schema1 |
    Given delete file "/opt/dble/SleepWhenClearIfSessionClosed.java" on "dble-1"
    Given delete file "/opt/dble/SleepWhenClearIfSessionClosed.java.log" on "dble-1"

  Scenario: close the connection at second stage: all nodes finished ddl #3
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                                                                                               | expect  | db      |
      | test | 111111 | conn_0 | True    | drop table if exists test_shard                                                                   | success | schema1 |
      | test | 111111 | conn_0 | True    | create table test_shard(id int(11) NOT NULL,c_flag char(255),c_decimal decimal(16,4))CHARSET=utf8 | success | schema1 |
    Given prepare a thread run btrace script "SleepWhen2ClearIfSessionClosed.java" in "dble-1"
    Given execute sqls in "dble-1" at background
      | user | passwd | conn   | toClose | sql                                | db      |
      | test | 111111 | conn_0 | True    | alter table test_shard drop c_flag | schema1 |
    Then check btrace "SleepWhen2ClearIfSessionClosed.java" output in "dble-1"
    """
    get into clearIfSessionClosed,start sleep
    """
    Given kill mysql query in "dble-1" forcely
    """
    alter table test_shard drop c_flag
    """
    Then check btrace "SleepWhen2ClearIfSessionClosed.java" output in "dble-1"
    """
    sleep end
    """
    Given stop btrace script "SleepWhen2ClearIfSessionClosed.java" in "dble-1"
    Given destroy btrace threads list
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                       | expect  | db      |
      | test | 111111 | conn_0 | True    | truncate table test_shard | success | schema1 |
    Given delete file "/opt/dble/SleepWhen2ClearIfSessionClosed.java" on "dble-1"
    Given delete file "/opt/dble/SleepWhen2ClearIfSessionClosed.java.log" on "dble-1"
